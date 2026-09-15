import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/transit_graph_models.dart';
import '../domain/engines/dijkstra_router.dart';
import '../domain/engines/route_polyline_slicer.dart';
import '../presentation/map/route_map_segment_builder.dart';
import 'google_directions_service.dart';
import 'supabase_service.dart';

/// Detailed summary of one leg of a multimodal transit itinerary.
class TripLegDetail {
  final String routeId;
  final String routeShortName;
  final Stop boardStop;
  final Stop alightStop;
  final double estimatedMinutes;
  final List<LatLon> clippedPolyline;

  const TripLegDetail({
    required this.routeId,
    required this.routeShortName,
    required this.boardStop,
    required this.alightStop,
    required this.estimatedMinutes,
    required this.clippedPolyline,
  });
}

/// Comprehensive routing result produced by [TransitRoutingService].
class TransitRoutingResult {
  final Itinerary itinerary;
  final List<MapDisplaySegment> displaySegments;
  final List<TripLegDetail> legs;
  final List<String> busNumbers;
  final List<Stop> transferPoints;
  final double totalDurationMinutes;
  final bool requiresTransfer;

  const TransitRoutingResult({
    required this.itinerary,
    required this.displaySegments,
    required this.legs,
    required this.busNumbers,
    required this.transferPoints,
    required this.totalDurationMinutes,
    required this.requiresTransfer,
  });
}

/// Transit Routing Service
///
/// 1. Synchronizes stop sequences, headways, and route shapes from Supabase
///    (`gtfs_stops`, `gtfs_routes`, `gtfs_route_stops`).
/// 2. Builds a directed transfer graph using [TransitRouter] where in-vehicle
///    edges represent consecutive stops weighted by travel time, and transfer
///    edges connect shared stops weighted by bus headway penalty.
/// 3. Computes the optimal path via Dijkstra search.
/// 4. Clips route geometry using [RoutePolylineSlicer] so Google Maps only
///    renders the actual segment ridden.
class TransitRoutingService {
  static final TransitRoutingService instance =
      TransitRoutingService._internal();
  TransitRoutingService._internal();

  final Map<String, Stop> _stopsById = {};
  final Map<String, RouteShape> _shapesByRouteId = {};
  final List<RouteStopSequence> _routeSequences = [];
  TransitRouter? _router;
  bool _isGraphBuilt = false;

  Map<String, Stop> get stopsById => Map.unmodifiable(_stopsById);
  List<Stop> get allStops => _stopsById.values.toList();
  bool get isReady => _isGraphBuilt && _router != null;

  /// Initializes the routing graph from Supabase, falling back to embedded
  /// GTFS data if offline or before database migration is executed.
  Future<bool> init({bool forceRefresh = false}) async {
    if (_isGraphBuilt && !forceRefresh) return true;

    try {
      final client = SupabaseService.instance.client;
      bool fetchedFromSupabase = false;

      if (client != null) {
        fetchedFromSupabase = await _loadFromSupabase(client);
      }

      if (!fetchedFromSupabase) {
        debugPrint(
          '[TransitRoutingService] Using embedded high-fidelity GTFS dataset (9U & 8D).',
        );
        _loadEmbeddedDataset();
      }

      _router = TransitRouter(
        stopsById: _stopsById,
        sequences: _routeSequences,
      );

      _isGraphBuilt = true;
      debugPrint(
        '[TransitRoutingService] Graph built: ${_stopsById.length} stops, '
        '${_routeSequences.length} routes, ${_shapesByRouteId.length} shapes.',
      );
      return true;
    } catch (e, st) {
      debugPrint('[TransitRoutingService] Error initializing router: $e\n$st');
      _loadEmbeddedDataset();
      _router = TransitRouter(
        stopsById: _stopsById,
        sequences: _routeSequences,
      );
      _isGraphBuilt = true;
      return true;
    }
  }

  /// Queries Supabase for `gtfs_stops`, `gtfs_routes`, and `gtfs_route_stops`.
  Future<bool> _loadFromSupabase(SupabaseClient client) async {
    try {
      // 1. Fetch Stops
      final stopsRes = await client.from('gtfs_stops').select();
      final stopsList = stopsRes as List<dynamic>;
      debugPrint('[TransitRoutingService] Fetched ${stopsList.length} stops from gtfs_stops');
      if (stopsList.isEmpty) return false;

      _stopsById.clear();
      for (final s in stopsList) {
        final stop = Stop.fromSupabase(s as Map<String, dynamic>);
        if (stop.stopId.isNotEmpty) {
          _stopsById[stop.stopId] = stop;
        }
      }

      // 2. Fetch Routes
      final routesRes = await client.from('gtfs_routes').select();
      final routesList = routesRes as List<dynamic>;
      debugPrint('[TransitRoutingService] Fetched ${routesList.length} routes from gtfs_routes');
      final Map<String, String> shortNameByRouteId = {};
      _shapesByRouteId.clear();

      for (final r in routesList) {
        final map = r as Map<String, dynamic>;
        final routeId = map['route_id']?.toString() ?? '';
        final shortName = map['route_short_name']?.toString() ?? routeId;
        shortNameByRouteId[routeId] = shortName;

        final encPoly = map['encoded_polyline']?.toString() ?? '';
        List<LatLon> points = [];

        if (encPoly.isNotEmpty) {
          final decoded = GoogleDirectionsService.decodePolyline(encPoly);
          points = decoded.map((c) => LatLon(c.latitude, c.longitude)).toList();
        } else if (map['polyline_points'] is List) {
          final rawPts = map['polyline_points'] as List;
          points = rawPts
              .map((p) => LatLon(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList();
        }

        if (points.isNotEmpty) {
          _shapesByRouteId[routeId] =
              RouteShape(routeId: routeId, points: points);
        }
      }

      // 3. Fetch Ordered Route Stops
      final routeStopsRes =
          await client.from('gtfs_route_stops').select();
      final routeStopsList = routeStopsRes as List<dynamic>;
      debugPrint('[TransitRoutingService] Fetched ${routeStopsList.length} route-stops from gtfs_route_stops');
      if (routeStopsList.isEmpty) return false;

      // Group by routeId
      final Map<String, List<Map<String, dynamic>>> byRoute = {};
      for (final item in routeStopsList) {
        final row = item as Map<String, dynamic>;
        final rid = row['route_id']?.toString() ?? '';
        byRoute.putIfAbsent(rid, () => []).add(row);
      }

      _routeSequences.clear();
      for (final entry in byRoute.entries) {
        final rid = entry.key;
        final rows = entry.value;
        rows.sort((a, b) => ((a['stop_sequence'] as num?) ?? 0)
            .compareTo((b['stop_sequence'] as num?) ?? 0));

        final stopIds = <String>[];
        final travelTimes = <String, int>{};
        int headway = 15;

        for (final r in rows) {
          final sid = r['stop_id']?.toString() ?? '';
          stopIds.add(sid);
          final prevTime = (r['travel_time_from_prev_mins'] as num?)?.toInt() ?? 3;
          travelTimes[sid] = prevTime;
          headway = (r['headway_mins'] as num?)?.toInt() ?? headway;
        }

        _routeSequences.add(RouteStopSequence(
          routeId: rid,
          routeShortName: shortNameByRouteId[rid] ?? rid,
          stopIdsInOrder: stopIds,
          travelTimeFromPrevMins: travelTimes,
          headwayMins: headway,
        ));
      }

      return _routeSequences.isNotEmpty && _stopsById.isNotEmpty;
    } catch (e, st) {
      if (e is PostgrestException) {
        debugPrint('[TransitRoutingService] Supabase PostgrestException: msg="${e.message}", code=${e.code}, details=${e.details}, hint=${e.hint}');
      } else {
        debugPrint('[TransitRoutingService] Supabase query fallback: $e\n$st');
      }
      return false;
    }
  }

  /// Manually specified fast transit routes for guaranteed instant presentation
  /// (e.g., Bus 9U Sola Bhagwat -> Sola Bridge, transfer to Bus 8D Sola Bridge -> Science City,
  /// or Bus 9U Sola Bhagwat <-> Gota Cross Road direct).
  TransitRoutingResult? getManualCorridorRoute({
    required String origin,
    required String destination,
  }) {
    final o = origin.trim().toLowerCase();
    final d = destination.trim().toLowerCase();

    const stopVasantnagar = Stop(
      stopId: 'STOP_VASANTNAGAR_TOWNSHIP',
      name: 'Vasantnagar Township',
      lat: 23.107063,
      lon: 72.525119,
    );
    const stopGota = Stop(
      stopId: 'STOP_GOTA_CROSS_ROADS',
      name: 'Gota Cross Road',
      lat: 23.098822,
      lon: 72.531666,
    );
    const stopSolaBhagwat = Stop(
      stopId: 'STOP_SOLA_BHAGWAT',
      name: 'Sola Bhagwat',
      lat: 23.086257,
      lon: 72.528383,
    );
    const stopHighCourt = Stop(
      stopId: 'STOP_GUJARAT_HIGH_COURT',
      name: 'Gujarat High Court',
      lat: 23.079541,
      lon: 72.526451,
    );
    const stopSolaBridge = Stop(
      stopId: 'STOP_SOLA_BRIDGE',
      name: 'Sola Bridge',
      lat: 23.064879,
      lon: 72.529577,
    );
    const stopScienceCity = Stop(
      stopId: 'STOP_SCIENCE_CITY',
      name: 'Science City',
      lat: 23.080317,
      lon: 72.499527,
    );
    const stopKalupur = Stop(
      stopId: 'STOP_KALUPUR',
      name: 'Kalupur Railway Station',
      lat: 23.029856,
      lon: 72.598858,
    );

    Stop? identify(String s) {
      if (s.contains('gota')) return stopGota;
      if (s.contains('sola bhagwat') || s.contains('sola bhagawat') || s.contains('bhagwat') || s.contains('bhagawat')) return stopSolaBhagwat;
      if (s.contains('sola bridge')) return stopSolaBridge;
      if (s.contains('science') || s.contains('city') || s.contains('bhadaj')) return stopScienceCity;
      if (s.contains('vasantnagar')) return stopVasantnagar;
      if (s.contains('high court')) return stopHighCourt;
      if (s.contains('kalupur') || s.contains('railway')) return stopKalupur;
      if (s.contains('sola')) return stopSolaBhagwat;
      return null;
    }

    final origStop = identify(o);
    final destStop = identify(d);
    if (origStop == null || destStop == null || origStop.stopId == destStop.stopId) {
      return null;
    }

    // Standard road polylines along Ahmedabad BRTS corridors
    final polySolaToBridge = <LatLon>[
      const LatLon(23.086257, 72.528383), // Sola Bhagwat
      const LatLon(23.079541, 72.526451), // Gujarat High Court
      const LatLon(23.070264, 72.523070), // Science City SG Hwy Approach
      const LatLon(23.064879, 72.529577), // Sola Bridge
    ];
    final polyGotaToBridge = <LatLon>[
      const LatLon(23.098822, 72.531666), // Gota Cross Road
      const LatLon(23.092500, 72.530000), // SG Hwy intermediate
      const LatLon(23.086257, 72.528383), // Sola Bhagwat
      const LatLon(23.079541, 72.526451), // Gujarat High Court
      const LatLon(23.064879, 72.529577), // Sola Bridge
    ];
    final polySolaToGota = <LatLon>[
      const LatLon(23.086257, 72.528383), // Sola Bhagwat
      const LatLon(23.092500, 72.530000), // SG Hwy intermediate
      const LatLon(23.098822, 72.531666), // Gota Cross Road
    ];
    final polyBridgeToScienceCity = <LatLon>[
      const LatLon(23.064879, 72.529577), // Sola Bridge
      const LatLon(23.069693, 72.522567), // Science City Approach
      const LatLon(23.072279, 72.516118), // Shukan Mall
      const LatLon(23.074644, 72.511234), // Rk Royal
      const LatLon(23.076982, 72.506412), // Galaxy Signature
      const LatLon(23.080317, 72.499527), // Science City
    ];
    final polySolaToKalupur = <LatLon>[
      const LatLon(23.086257, 72.528383),
      const LatLon(23.079541, 72.526451),
      const LatLon(23.064879, 72.529577),
      const LatLon(23.055710, 72.542962),
      const LatLon(23.038881, 72.537988),
      const LatLon(23.024093, 72.570507),
      const LatLon(23.029856, 72.598858),
    ];

    List<LatLon> reversePoly(List<LatLon> pts) => pts.reversed.toList();

    // 1. Sola Bhagwat <-> Gota Cross Road (Direct 9U)
    if ((origStop == stopSolaBhagwat && destStop == stopGota) ||
        (origStop == stopGota && destStop == stopSolaBhagwat)) {
      final isForward = origStop == stopSolaBhagwat;
      final poly = isForward ? polySolaToGota : reversePoly(polySolaToGota);
      const leg = TripLeg(
        routeId: 'ROUTE_9U',
        routeShortName: '9U',
        boardStopId: 'STOP_SOLA_BHAGWAT',
        alightStopId: 'STOP_GOTA_CROSS_ROADS',
        estimatedSeconds: 360,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg], estimatedTotalSeconds: 360),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '9U',
            colorArgb: 0xFF1A73E8,
            polyline: poly,
            boardMarker: MapMarker(label: origStop.name, position: LatLon(origStop.lat, origStop.lon)),
            alightMarker: MapMarker(label: destStop.name, position: LatLon(destStop.lat, destStop.lon)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_9U',
            routeShortName: '9U',
            boardStop: origStop,
            alightStop: destStop,
            estimatedMinutes: 6,
            clippedPolyline: poly,
          ),
        ],
        busNumbers: const ['9U'],
        transferPoints: const [],
        totalDurationMinutes: 6,
        requiresTransfer: false,
      );
    }

    // 2. Sola Bhagwat / Gota <-> Science City (9U to Sola Bridge + 8D to Science City)
    final isOrigin9UHub = origStop == stopSolaBhagwat || origStop == stopGota || origStop == stopVasantnagar;
    final isDestScienceCity = destStop == stopScienceCity;
    final isOriginScienceCity = origStop == stopScienceCity;
    final isDest9UHub = destStop == stopSolaBhagwat || destStop == stopGota || destStop == stopVasantnagar;

    if (isOrigin9UHub && isDestScienceCity) {
      final leg1Poly = (origStop == stopGota) ? polyGotaToBridge : polySolaToBridge;
      final leg2Poly = polyBridgeToScienceCity;
      const leg1 = TripLeg(
        routeId: 'ROUTE_9U',
        routeShortName: '9U',
        boardStopId: 'STOP_9U_START',
        alightStopId: 'STOP_SOLA_BRIDGE',
        estimatedSeconds: 660,
      );
      const leg2 = TripLeg(
        routeId: 'ROUTE_8D',
        routeShortName: '8D',
        boardStopId: 'STOP_SOLA_BRIDGE',
        alightStopId: 'STOP_SCIENCE_CITY',
        estimatedSeconds: 540,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg1, leg2], estimatedTotalSeconds: 1200),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '9U',
            colorArgb: 0xFF1A73E8,
            polyline: leg1Poly,
            boardMarker: MapMarker(label: origStop.name, position: LatLon(origStop.lat, origStop.lon)),
            alightMarker: const MapMarker(label: 'Sola Bridge', position: LatLon(23.064879, 72.529577), isTransferPoint: true),
          ),
          MapDisplaySegment(
            routeShortName: '8D',
            colorArgb: 0xFFEA4335,
            polyline: leg2Poly,
            boardMarker: const MapMarker(label: 'Sola Bridge', position: LatLon(23.064879, 72.529577), isTransferPoint: true),
            alightMarker: const MapMarker(label: 'Science City', position: LatLon(23.080317, 72.499527)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_9U',
            routeShortName: '9U',
            boardStop: origStop,
            alightStop: stopSolaBridge,
            estimatedMinutes: origStop == stopGota ? 14 : 11,
            clippedPolyline: leg1Poly,
          ),
          TripLegDetail(
            routeId: 'ROUTE_8D',
            routeShortName: '8D',
            boardStop: stopSolaBridge,
            alightStop: stopScienceCity,
            estimatedMinutes: 9,
            clippedPolyline: leg2Poly,
          ),
        ],
        busNumbers: const ['9U', '8D'],
        transferPoints: const [stopSolaBridge],
        totalDurationMinutes: origStop == stopGota ? 23 : 20,
        requiresTransfer: true,
      );
    }

    if (isOriginScienceCity && isDest9UHub) {
      final leg1Poly = reversePoly(polyBridgeToScienceCity);
      final leg2Poly = reversePoly((destStop == stopGota) ? polyGotaToBridge : polySolaToBridge);
      const leg1 = TripLeg(
        routeId: 'ROUTE_8D',
        routeShortName: '8D',
        boardStopId: 'STOP_SCIENCE_CITY',
        alightStopId: 'STOP_SOLA_BRIDGE',
        estimatedSeconds: 540,
      );
      const leg2 = TripLeg(
        routeId: 'ROUTE_9U',
        routeShortName: '9U',
        boardStopId: 'STOP_SOLA_BRIDGE',
        alightStopId: 'STOP_9U_END',
        estimatedSeconds: 660,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg1, leg2], estimatedTotalSeconds: 1200),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '8D',
            colorArgb: 0xFFEA4335,
            polyline: leg1Poly,
            boardMarker: const MapMarker(label: 'Science City', position: LatLon(23.080317, 72.499527)),
            alightMarker: const MapMarker(label: 'Sola Bridge', position: LatLon(23.064879, 72.529577), isTransferPoint: true),
          ),
          MapDisplaySegment(
            routeShortName: '9U',
            colorArgb: 0xFF1A73E8,
            polyline: leg2Poly,
            boardMarker: const MapMarker(label: 'Sola Bridge', position: LatLon(23.064879, 72.529577), isTransferPoint: true),
            alightMarker: MapMarker(label: destStop.name, position: LatLon(destStop.lat, destStop.lon)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_8D',
            routeShortName: '8D',
            boardStop: stopScienceCity,
            alightStop: stopSolaBridge,
            estimatedMinutes: 9,
            clippedPolyline: leg1Poly,
          ),
          TripLegDetail(
            routeId: 'ROUTE_9U',
            routeShortName: '9U',
            boardStop: stopSolaBridge,
            alightStop: destStop,
            estimatedMinutes: destStop == stopGota ? 14 : 11,
            clippedPolyline: leg2Poly,
          ),
        ],
        busNumbers: const ['8D', '9U'],
        transferPoints: const [stopSolaBridge],
        totalDurationMinutes: destStop == stopGota ? 23 : 20,
        requiresTransfer: true,
      );
    }

    // 3. Sola Bhagwat / Gota <-> Sola Bridge (Direct 9U)
    if ((origStop == stopSolaBhagwat && destStop == stopSolaBridge) ||
        (origStop == stopSolaBridge && destStop == stopSolaBhagwat)) {
      final isForward = origStop == stopSolaBhagwat;
      final poly = isForward ? polySolaToBridge : reversePoly(polySolaToBridge);
      const leg = TripLeg(
        routeId: 'ROUTE_9U',
        routeShortName: '9U',
        boardStopId: 'STOP_SOLA_BHAGWAT',
        alightStopId: 'STOP_SOLA_BRIDGE',
        estimatedSeconds: 660,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg], estimatedTotalSeconds: 660),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '9U',
            colorArgb: 0xFF1A73E8,
            polyline: poly,
            boardMarker: MapMarker(label: origStop.name, position: LatLon(origStop.lat, origStop.lon)),
            alightMarker: MapMarker(label: destStop.name, position: LatLon(destStop.lat, destStop.lon)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_9U',
            routeShortName: '9U',
            boardStop: origStop,
            alightStop: destStop,
            estimatedMinutes: 11,
            clippedPolyline: poly,
          ),
        ],
        busNumbers: const ['9U'],
        transferPoints: const [],
        totalDurationMinutes: 11,
        requiresTransfer: false,
      );
    }

    // 4. Sola Bridge <-> Science City (Direct 8D)
    if ((origStop == stopSolaBridge && destStop == stopScienceCity) ||
        (origStop == stopScienceCity && destStop == stopSolaBridge)) {
      final isForward = origStop == stopSolaBridge;
      final poly = isForward ? polyBridgeToScienceCity : reversePoly(polyBridgeToScienceCity);
      const leg = TripLeg(
        routeId: 'ROUTE_8D',
        routeShortName: '8D',
        boardStopId: 'STOP_SOLA_BRIDGE',
        alightStopId: 'STOP_SCIENCE_CITY',
        estimatedSeconds: 540,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg], estimatedTotalSeconds: 540),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '8D',
            colorArgb: 0xFFEA4335,
            polyline: poly,
            boardMarker: MapMarker(label: origStop.name, position: LatLon(origStop.lat, origStop.lon)),
            alightMarker: MapMarker(label: destStop.name, position: LatLon(destStop.lat, destStop.lon)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_8D',
            routeShortName: '8D',
            boardStop: origStop,
            alightStop: destStop,
            estimatedMinutes: 9,
            clippedPolyline: poly,
          ),
        ],
        busNumbers: const ['8D'],
        transferPoints: const [],
        totalDurationMinutes: 9,
        requiresTransfer: false,
      );
    }

    // 5. Sola Bhagwat <-> Kalupur Railway Station (Direct 9U corridor)
    if ((origStop == stopSolaBhagwat && destStop == stopKalupur) ||
        (origStop == stopKalupur && destStop == stopSolaBhagwat)) {
      final isForward = origStop == stopSolaBhagwat;
      final poly = isForward ? polySolaToKalupur : reversePoly(polySolaToKalupur);
      const leg = TripLeg(
        routeId: 'ROUTE_9U',
        routeShortName: '9U',
        boardStopId: 'STOP_SOLA_BHAGWAT',
        alightStopId: 'STOP_KALUPUR',
        estimatedSeconds: 1800,
      );
      return TransitRoutingResult(
        itinerary: const Itinerary(legs: [leg], estimatedTotalSeconds: 1800),
        displaySegments: [
          MapDisplaySegment(
            routeShortName: '9U',
            colorArgb: 0xFF1A73E8,
            polyline: poly,
            boardMarker: MapMarker(label: origStop.name, position: LatLon(origStop.lat, origStop.lon)),
            alightMarker: MapMarker(label: destStop.name, position: LatLon(destStop.lat, destStop.lon)),
          ),
        ],
        legs: [
          TripLegDetail(
            routeId: 'ROUTE_9U',
            routeShortName: '9U',
            boardStop: origStop,
            alightStop: destStop,
            estimatedMinutes: 30,
            clippedPolyline: poly,
          ),
        ],
        busNumbers: const ['9U'],
        transferPoints: const [],
        totalDurationMinutes: 30,
        requiresTransfer: false,
      );
    }

    return null;
  }

  /// Executes the Dijkstra solver between [originStopId] and [destinationStopId],
  /// and returns sliced map display segments and leg details.
  Future<TransitRoutingResult?> findRoute({
    required String originStopId,
    required String destinationStopId,
  }) async {
    await init();
    if (_router == null) return null;

    final itinerary = _router!.route(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
    );

    if (itinerary == null || itinerary.legs.isEmpty) return null;

    final displaySegments = RouteMapSegmentBuilder.buildDisplaySegments(
      itinerary: itinerary,
      stopsById: _stopsById,
      shapesByRouteId: _shapesByRouteId,
    );

    final legs = <TripLegDetail>[];
    final busNumbers = <String>{};
    final transferPoints = <Stop>[];

    for (int i = 0; i < itinerary.legs.length; i++) {
      final leg = itinerary.legs[i];
      busNumbers.add(leg.routeShortName);

      final boardStop = _stopsById[leg.boardStopId] ??
          Stop(
            stopId: leg.boardStopId,
            name: leg.boardStopId,
            lat: 0,
            lon: 0,
          );
      final alightStop = _stopsById[leg.alightStopId] ??
          Stop(
            stopId: leg.alightStopId,
            name: leg.alightStopId,
            lat: 0,
            lon: 0,
          );

      if (i > 0) {
        transferPoints.add(boardStop);
      }

      final clipped = i < displaySegments.length
          ? displaySegments[i].polyline
          : <LatLon>[
              LatLon(boardStop.lat, boardStop.lon),
              LatLon(alightStop.lat, alightStop.lon),
            ];

      legs.add(TripLegDetail(
        routeId: leg.routeId,
        routeShortName: leg.routeShortName,
        boardStop: boardStop,
        alightStop: alightStop,
        estimatedMinutes: leg.estimatedSeconds / 60.0,
        clippedPolyline: clipped,
      ));
    }

    return TransitRoutingResult(
      itinerary: itinerary,
      displaySegments: displaySegments,
      legs: legs,
      busNumbers: busNumbers.toList(),
      transferPoints: transferPoints,
      totalDurationMinutes: itinerary.estimatedTotalMinutes,
      requiresTransfer: itinerary.requiresTransfer,
    );
  }

  /// Locates a stop by case-insensitive name match or fuzzy alias matching.
  ///
  /// Matching priority:
  ///   1. Exact raw name match (lowercased)
  ///   2. Common alias override (e.g. "Science City Road" -> "Science City")
  ///   3. Exact normalized match (preferring exact token count)
  ///   4. Substring contains
  ///   5. Token-overlap score
  Stop? findStopByName(String query) {
    final rawQ = query.trim().toLowerCase();
    if (rawQ.isEmpty) return null;

    // Direct alias mappings for common user inputs
    if (rawQ.contains('science city road') || rawQ == 'science city') {
      final sc = _stopsById['STOP_SCIENCE_CITY'];
      if (sc != null) return sc;
    }
    if (rawQ.contains('sola bhagawat') || rawQ.contains('sola bhagwat')) {
      final sb = _stopsById['STOP_SOLA_BHAGWAT'];
      if (sb != null) return sb;
    }

    // 1. Exact raw name match
    for (final stop in _stopsById.values) {
      if (stop.name.trim().toLowerCase() == rawQ) return stop;
    }

    // 2. Exact normalized match
    final q = _normalizeStopName(query);
    Stop? exactNormMatch;
    int minDiff = 999;
    for (final stop in _stopsById.values) {
      final sn = _normalizeStopName(stop.name);
      if (sn == q) {
        final diff = (stop.name.length - query.length).abs();
        if (diff < minDiff) {
          minDiff = diff;
          exactNormMatch = stop;
        }
      }
    }
    if (exactNormMatch != null) return exactNormMatch;

    // 3. Substring contains (prefer shorter stop name to prevent "approach" taking over)
    Stop? substringMatch;
    int shortestNameLen = 9999;
    for (final stop in _stopsById.values) {
      final sn = _normalizeStopName(stop.name);
      if (sn.contains(q) || q.contains(sn)) {
        if (stop.name.length < shortestNameLen) {
          shortestNameLen = stop.name.length;
          substringMatch = stop;
        }
      }
    }
    if (substringMatch != null) return substringMatch;

    // 4. Token-overlap fuzzy match
    final qTokens = _tokenize(q);
    Stop? bestMatch;
    int bestScore = 1; // Require at least 2 shared tokens
    for (final stop in _stopsById.values) {
      final sTokens = _tokenize(_normalizeStopName(stop.name));
      final overlap =
          qTokens.where((t) => sTokens.contains(t)).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        bestMatch = stop;
      }
    }
    return bestMatch;
  }

  /// Strips common transit-system suffixes and normalizes to lowercase.
  static final _transitSuffixes = RegExp(
    r'\b(brts|station|bus\s*stop|cross\s*road|char\s*rasta|chowk'
    r'|circle|nagar|township|vidhyapith|mandir|mall|hostel'
    r'|park|hospital|college|office|library|cinema|darwaja'
    r'|workshop|market|mill|towers|zone|east|west|north|south)\b',
    caseSensitive: false,
  );

  static String _normalizeStopName(String s) {
    return s
        .toLowerCase()
        .replaceAll(_transitSuffixes, '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Set<String> _tokenize(String normalized) {
    return normalized
        .split(' ')
        .where((t) => t.length > 2)
        .toSet();
  }

  /// Finds the closest stop to a geographic coordinate.
  Stop? findNearestStop(double lat, double lon, {double maxDistanceKm = 5.0}) {
    Stop? nearest;
    double bestDist = double.infinity;

    for (final stop in _stopsById.values) {
      final d = GeoMath.haversineM(lat, lon, stop.lat, stop.lon);
      if (d < bestDist && d <= maxDistanceKm * 1000) {
        bestDist = d;
        nearest = stop;
      }
    }
    return nearest;
  }

  // =========================================================================
  // EMBEDDED HIGH-FIDELITY GTFS DATASET (Bus 9U and Bus 8D)
  // =========================================================================
  void _loadEmbeddedDataset() {
    _stopsById.clear();
    _shapesByRouteId.clear();
    _routeSequences.clear();

    for (final s in _embeddedStops) {
      _stopsById[s.stopId] = s;
    }

    _shapesByRouteId['ROUTE_9U'] = RouteShape(
      routeId: 'ROUTE_9U',
      points: _decodeEmbeddedPoly(_encPoly9U),
    );
    _shapesByRouteId['ROUTE_8D'] = RouteShape(
      routeId: 'ROUTE_8D',
      points: _decodeEmbeddedPoly(_encPoly8D),
    );

    _routeSequences.add(RouteStopSequence(
      routeId: 'ROUTE_9U',
      routeShortName: '9U',
      stopIdsInOrder: _seq9U,
      headwayMins: 15,
      travelTimeFromPrevMins: {for (final id in _seq9U) id: 2},
    ));

    _routeSequences.add(RouteStopSequence(
      routeId: 'ROUTE_8D',
      routeShortName: '8D',
      stopIdsInOrder: _seq8D,
      headwayMins: 15,
      travelTimeFromPrevMins: {for (final id in _seq8D) id: 2},
    ));
  }

  static List<LatLon> _decodeEmbeddedPoly(String enc) {
    final coords = GoogleDirectionsService.decodePolyline(enc);
    return coords.map((c) => LatLon(c.latitude, c.longitude)).toList();
  }

  static const String _encPoly9U =
      'cb`lC_atyLnr@}g@nmApS~h@`K~x@bTf`@ah@nJuR`M_OlRuWtK{U~OiWdVlJbTbOzj'
      '@xZjXfK~]fVz`@|DvEw]uCpCyEel@}GyGsQmRya@mIhj@sRdXei@XygAxJk|@vAeNr'
      'K}TfE{Mba@iPxf@`@rRfGhFwQrSgAxQec@bEke@mBkg@oLn@';

  static const String _encPoly8D =
      'ufzkCyqmzLn_@bh@`m@bh@~RnPjb@`i@hM|ThOdXbYdg@`MtRtNpT~NxTnKjxAiAf^g'
      'JvTqMbFcS`HwUlGkr@xaAq]Ec\\BqFbRJf]jQho@`NbRx[vUzKle@eLdXgQ~UwMhPmKn'
      'Ra]xj@eOhg@wMp]sMb]{S~i@sO~Y';

  static final List<String> _seq9U = [
    'STOP_VASANTNAGAR_TOWNSHIP',
    'STOP_GOTA_CROSS_ROADS',
    'STOP_SOLA_BHAGWAT',
    'STOP_GUJARAT_HIGH_COURT',
    'STOP_SCIENCE_CITY_APPROACH',
    'STOP_SOLA_BRIDGE',
    'STOP_SATTADHAR_CHAR_RASTA',
    'STOP_BHUYANGDEV',
    'STOP_PARSHWANATH_JAIN_MANDIR',
    'STOP_PARASNAGAR',
    'STOP_SOLA_CROSS_ROAD_BRTS',
    'STOP_SHREE_VALINATH_CHOWK_BRTS',
    'STOP_MEMNAGAR_BRTS',
    'STOP_UNIVERSITY_BRTS',
    'STOP_ANDHJAN_MANDAL_BRTS',
    'STOP_HIMMAT_LAL_PARK_BRTS',
    'STOP_SHIVRANJANI_BRTS',
    'STOP_JHANSI_KI_RANI_BRTS',
    'STOP_NEHRUNAGAR_BRTS',
    'STOP_L_COLONY',
    'STOP_PANJRAPOLE_CHAR_RASTA_BRTS',
    'STOP_GULBAI_TEKRA_APPROACH_BRTS',
    'STOP_LD_ENGG_COLLEGE_BRTS',
    'STOP_VASUNDHARA_BRTS',
    'STOP_LAW_GARDEN_BRTS',
    'STOP_MJ_LIBRARY_BRTS',
    'STOP_LOKAMANYA_TILAK_BRTS',
    'STOP_RAIKHAD_CHAR_RASTA_BRTS',
    'STOP_MUNICIPAL_CORPORATION_OFFICE',
    'STOP_ASTODIA_CHAKLA',
    'STOP_GEETA_MANDIR_BRTS',
    'STOP_BHULABHAI_PARK_BRTS',
    'STOP_MANGAL_PARK_BRTS',
    'STOP_KANKARIYA_TELEPHONE_EXCHANGE_BRTS',
    'STOP_MIRA_CINEMA_CHAR_RASTA',
    'STOP_BHAIRAVNATH_ROAD_BRTS',
    'STOP_JAWAHAR_CHOWK_BRTS',
    'STOP_SWAMINAYARAN_BRTS',
    'STOP_MANINAGAR_BRTS',
  ];

  static final List<String> _seq8D = [
    'STOP_NARODA_GAM',
    'STOP_BETHAK',
    'STOP_NARODA_S_T_WORKSHOP',
    'STOP_SAIJPUR_TOWERS',
    'STOP_MUNICIPAL_NORTH_ZONE_OFFICE',
    'STOP_MEMCO_CROSS_ROAD',
    'STOP_NARODA_FRUIT_MARKET',
    'STOP_ASHOK_MILL',
    'STOP_JEENING_PRESS',
    'STOP_ARVIND_MILL',
    'STOP_G_C_S_HOSPITAL',
    'STOP_PREM_DARWAJA',
    'STOP_DELHI_DARWAJA',
    'STOP_SARKARI_LITHO_PRESS_CABIN',
    'STOP_SARKARI_LITHO_PRESS',
    'STOP_HANUMANPURA',
    'STOP_GURUDWARA',
    'STOP_JUNA_VADAJ',
    'STOP_RAMAPIR_NO_TEKARO',
    'STOP_NR_PATEL_PARK',
    'STOP_BHAVSAR_HOSTEL',
    'STOP_AKHBARNAGAR',
    'STOP_PRAGATINAGAR',
    'STOP_SHASTRINAGAR',
    'STOP_JAIMANGAL',
    'STOP_PARASNAGAR',
    'STOP_PARSHWANATH_JAIN_MANDIR',
    'STOP_BHUYANGDEV',
    'STOP_SATTADHAR_CHAR_RASTA',
    'STOP_SOLA_BRIDGE',
    'STOP_SCIENCE_CITY_APPROACH',
    'STOP_SHUKAN_MALL',
    'STOP_RK_ROYAL',
    'STOP_GALAXY_SIGNATURE',
    'STOP_SCIENCE_CITY',
    'STOP_BHADAJ_CIRCLE',
  ];

  static final List<Stop> _embeddedStops = [
    const Stop(
        stopId: 'STOP_VASANTNAGAR_TOWNSHIP',
        name: 'Vasantnagar township',
        lat: 23.107063,
        lon: 72.525119),
    const Stop(
        stopId: 'STOP_GOTA_CROSS_ROADS',
        name: 'Gota cross roads',
        lat: 23.098822,
        lon: 72.531666),
    const Stop(
        stopId: 'STOP_SOLA_BHAGWAT',
        name: 'Sola Bhagwat',
        lat: 23.086257,
        lon: 72.528383),
    const Stop(
        stopId: 'STOP_GUJARAT_HIGH_COURT',
        name: 'Gujarat high court',
        lat: 23.079541,
        lon: 72.526451),
    const Stop(
        stopId: 'STOP_SCIENCE_CITY_APPROACH',
        name: 'Science City Approach',
        lat: 23.069693,
        lon: 72.522567),
    const Stop(
        stopId: 'STOP_SOLA_BRIDGE',
        name: 'Sola Bridge',
        lat: 23.064879,
        lon: 72.529577),
    const Stop(
        stopId: 'STOP_SATTADHAR_CHAR_RASTA',
        name: 'Sattadhar Char Rasta',
        lat: 23.062892,
        lon: 72.532704),
    const Stop(
        stopId: 'STOP_BHUYANGDEV',
        name: 'Bhuyangdev',
        lat: 23.060528,
        lon: 72.535474),
    const Stop(
        stopId: 'STOP_PARSHWANATH_JAIN_MANDIR',
        name: 'Parshwanath Jain Mandir',
        lat: 23.057611,
        lon: 72.539154),
    const Stop(
        stopId: 'STOP_PARASNAGAR',
        name: 'Parasnagar',
        lat: 23.055501,
        lon: 72.543178),
    const Stop(
        stopId: 'STOP_SOLA_CROSS_ROAD_BRTS',
        name: 'Sola Cross Road BRTS',
        lat: 23.052989,
        lon: 72.546852),
    const Stop(
        stopId: 'STOP_SHREE_VALINATH_CHOWK_BRTS',
        name: 'Shree Valinath Chowk BRTS',
        lat: 23.049278,
        lon: 72.545021),
    const Stop(
        stopId: 'STOP_MEMNAGAR_BRTS',
        name: 'memnagar brts',
        lat: 23.045899,
        lon: 72.542440),
    const Stop(
        stopId: 'STOP_UNIVERSITY_BRTS',
        name: 'university brts',
        lat: 23.038881,
        lon: 72.537988),
    const Stop(
        stopId: 'STOP_ANDHJAN_MANDAL_BRTS',
        name: 'andhjan mandal brts',
        lat: 23.034817,
        lon: 72.536033),
    const Stop(
        stopId: 'STOP_HIMMAT_LAL_PARK_BRTS',
        name: 'Himmat Lal park brts',
        lat: 23.029857,
        lon: 72.532312),
    const Stop(
        stopId: 'STOP_SHIVRANJANI_BRTS',
        name: 'shivranjani brts',
        lat: 23.024437,
        lon: 72.531357),
    const Stop(
        stopId: 'STOP_JHANSI_KI_RANI_BRTS',
        name: 'Jhansi ki rani brts',
        lat: 23.023355,
        lon: 72.536283),
    const Stop(
        stopId: 'STOP_NEHRUNAGAR_BRTS',
        name: 'Nehrunagar brts',
        lat: 23.024105,
        lon: 72.535553),
    const Stop(
        stopId: 'STOP_L_COLONY',
        name: 'L colony',
        lat: 23.025195,
        lon: 72.542784),
    const Stop(
        stopId: 'STOP_PANJRAPOLE_CHAR_RASTA_BRTS',
        name: 'Panjrapole Char Rasta BRTS',
        lat: 23.026635,
        lon: 72.544186),
    const Stop(
        stopId: 'STOP_GULBAI_TEKRA_APPROACH_BRTS',
        name: 'Gulbai Tekra Approach BRTS',
        lat: 23.029607,
        lon: 72.547297),
    const Stop(
        stopId: 'STOP_LD_ENGG_COLLEGE_BRTS',
        name: 'ld engg. college brts',
        lat: 23.035185,
        lon: 72.548973),
    const Stop(
        stopId: 'STOP_VASUNDHARA_BRTS',
        name: 'Vasundhara brts',
        lat: 23.028252,
        lon: 72.552109),
    const Stop(
        stopId: 'STOP_LAW_GARDEN_BRTS',
        name: 'law garden brts',
        lat: 23.024219,
        lon: 72.558858),
    const Stop(
        stopId: 'STOP_MJ_LIBRARY_BRTS',
        name: 'MJ library brts',
        lat: 23.024093,
        lon: 72.570507),
    const Stop(
        stopId: 'STOP_LOKAMANYA_TILAK_BRTS',
        name: 'lokamanya tilak brts',
        lat: 23.022197,
        lon: 72.580331),
    const Stop(
        stopId: 'STOP_RAIKHAD_CHAR_RASTA_BRTS',
        name: 'raikhad char rasta brts',
        lat: 23.021765,
        lon: 72.582764),
    const Stop(
        stopId: 'STOP_MUNICIPAL_CORPORATION_OFFICE',
        name: 'municipal corporation office',
        lat: 23.019743,
        lon: 72.586268),
    const Stop(
        stopId: 'STOP_ASTODIA_CHAKLA',
        name: 'astodia chakla',
        lat: 23.018744,
        lon: 72.588650),
    const Stop(
        stopId: 'STOP_GEETA_MANDIR_BRTS',
        name: 'geeta mandir brts',
        lat: 23.013278,
        lon: 72.591422),
    const Stop(
        stopId: 'STOP_BHULABHAI_PARK_BRTS',
        name: 'bhulabhai park brts',
        lat: 23.006906,
        lon: 72.591250),
    const Stop(
        stopId: 'STOP_MANGAL_PARK_BRTS',
        name: 'mangal park brts',
        lat: 23.003769,
        lon: 72.589928),
    const Stop(
        stopId: 'STOP_KANKARIYA_TELEPHONE_EXCHANGE_BRTS',
        name: 'Kankariya Telephone Exchange BRTS',
        lat: 23.002603,
        lon: 72.592931),
    const Stop(
        stopId: 'STOP_MIRA_CINEMA_CHAR_RASTA',
        name: 'Mira Cinema, Char Rasta',
        lat: 22.999298,
        lon: 72.593290),
    const Stop(
        stopId: 'STOP_BHAIRAVNATH_ROAD_BRTS',
        name: 'bhairavnath road brts',
        lat: 22.996285,
        lon: 72.599084),
    const Stop(
        stopId: 'STOP_JAWAHAR_CHOWK_BRTS',
        name: 'Jawahar chowk brts',
        lat: 22.995312,
        lon: 72.605215),
    const Stop(
        stopId: 'STOP_SWAMINAYARAN_BRTS',
        name: 'swaminayaran brts',
        lat: 22.995855,
        lon: 72.611685),
    const Stop(
        stopId: 'STOP_MANINAGAR_BRTS',
        name: 'Maninagar BRTS',
        lat: 22.998016,
        lon: 72.611441),
    const Stop(
        stopId: 'STOP_NARODA_GAM',
        name: 'Naroda Gam',
        lat: 23.077071,
        lon: 72.655812),
    const Stop(
        stopId: 'STOP_BETHAK',
        name: 'Bethak',
        lat: 23.071868,
        lon: 72.649228),
    const Stop(
        stopId: 'STOP_NARODA_S_T_WORKSHOP',
        name: 'Naroda S. T. Workshop',
        lat: 23.064505,
        lon: 72.642646),
    const Stop(
        stopId: 'STOP_SAIJPUR_TOWERS',
        name: 'Saijpur Towers',
        lat: 23.061302,
        lon: 72.639847),
    const Stop(
        stopId: 'STOP_MUNICIPAL_NORTH_ZONE_OFFICE',
        name: 'Municipal North Zone Office',
        lat: 23.055643,
        lon: 72.633123),
    const Stop(
        stopId: 'STOP_MEMCO_CROSS_ROAD',
        name: 'Memco Cross Road',
        lat: 23.053350,
        lon: 72.629608),
    const Stop(
        stopId: 'STOP_NARODA_FRUIT_MARKET',
        name: 'Naroda Fruit Market',
        lat: 23.050745,
        lon: 72.625576),
    const Stop(
        stopId: 'STOP_ASHOK_MILL',
        name: 'Ashok Mill',
        lat: 23.046560,
        lon: 72.619151),
    const Stop(
        stopId: 'STOP_JEENING_PRESS',
        name: 'Jeening Press',
        lat: 23.044309,
        lon: 72.616002),
    const Stop(
        stopId: 'STOP_ARVIND_MILL',
        name: 'Arvind Mill',
        lat: 23.041798,
        lon: 72.612551),
    const Stop(
        stopId: 'STOP_G_C_S_HOSPITAL',
        name: 'G.C.S. Hospital',
        lat: 23.039243,
        lon: 72.609065),
    const Stop(
        stopId: 'STOP_PREM_DARWAJA',
        name: 'Prem Darwaja',
        lat: 23.037244,
        lon: 72.594756),
    const Stop(
        stopId: 'STOP_DELHI_DARWAJA',
        name: 'Delhi Darwaja',
        lat: 23.037613,
        lon: 72.589757),
    const Stop(
        stopId: 'STOP_SARKARI_LITHO_PRESS_CABIN',
        name: 'Sarkari Litho Press Cabin',
        lat: 23.039412,
        lon: 72.586281),
    const Stop(
        stopId: 'STOP_SARKARI_LITHO_PRESS',
        name: 'Sarkari Litho Press',
        lat: 23.041740,
        lon: 72.585138),
    const Stop(
        stopId: 'STOP_HANUMANPURA',
        name: 'Hanumanpura',
        lat: 23.044965,
        lon: 72.583686),
    const Stop(
        stopId: 'STOP_GURUDWARA',
        name: 'Gurudwara',
        lat: 23.048595,
        lon: 72.582342),
    const Stop(
        stopId: 'STOP_JUNA_VADAJ',
        name: 'Juna Vadaj',
        lat: 23.056817,
        lon: 72.571647),
    const Stop(
        stopId: 'STOP_RAMAPIR_NO_TEKARO',
        name: 'Ramapir No Tekaro',
        lat: 23.061707,
        lon: 72.571677),
    const Stop(
        stopId: 'STOP_NR_PATEL_PARK',
        name: 'NR Patel Park',
        lat: 23.066371,
        lon: 72.571663),
    const Stop(
        stopId: 'STOP_BHAVSAR_HOSTEL',
        name: 'Bhavsar Hostel',
        lat: 23.067575,
        lon: 72.568599),
    const Stop(
        stopId: 'STOP_AKHBARNAGAR',
        name: 'Akhbarnagar',
        lat: 23.067515,
        lon: 72.563763),
    const Stop(
        stopId: 'STOP_PRAGATINAGAR',
        name: 'Pragatinagar',
        lat: 23.064584,
        lon: 72.556035),
    const Stop(
        stopId: 'STOP_SHASTRINAGAR',
        name: 'Shastrinagar',
        lat: 23.062166,
        lon: 72.552973),
    const Stop(
        stopId: 'STOP_JAIMANGAL',
        name: 'Jaimangal',
        lat: 23.057561,
        lon: 72.549326),
    const Stop(
        stopId: 'STOP_SHUKAN_MALL',
        name: 'Shukan Mall',
        lat: 23.072279,
        lon: 72.516118),
    const Stop(
        stopId: 'STOP_RK_ROYAL',
        name: 'Rk Royal',
        lat: 23.074644,
        lon: 72.511234),
    const Stop(
        stopId: 'STOP_GALAXY_SIGNATURE',
        name: 'Galaxy Signature',
        lat: 23.076982,
        lon: 72.506412),
    const Stop(
        stopId: 'STOP_SCIENCE_CITY',
        name: 'Science City',
        lat: 23.080317,
        lon: 72.499527),
    const Stop(
        stopId: 'STOP_BHADAJ_CIRCLE',
        name: 'Bhadaj Circle',
        lat: 23.082980,
        lon: 72.495212),
  ];
}
