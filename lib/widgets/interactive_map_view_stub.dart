import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/transit_map_config.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';
import '../services/native_map_registry.dart';

/// Platform implementation of interactive map for non-web environments (Android APK, iOS, Desktop)
/// Provides smooth 2D pan/drag, fling inertia, multi-touch pinch zoom, double-tap zoom,
/// dynamic Google Maps / OSM tiles, custom polylines, stop markers, and live GPS pins.
Widget buildPlatformMapView({
  required Key? key,
  required String divId,
  required TransitRouteResult? route,
  required bool isSatellite,
  required String? scope,
  required TransitGpsLocation? gpsLocation,
  required bool isDarkMode,
  String? transitResultJson,
  VoidCallback? onMapReady,
}) {
  return _NativeInteractiveMapView(
    key: key,
    divId: divId,
    route: route,
    isSatellite: isSatellite,
    scope: scope,
    gpsLocation: gpsLocation,
    isDarkMode: isDarkMode,
    transitResultJson: transitResultJson,
    onMapReady: onMapReady,
  );
}

class _TransitLegData {
  final List<LatLng> points;
  final Color color;
  final String busNumber;
  final LatLng boardCoord;
  final String boardName;
  final LatLng alightCoord;
  final String alightName;
  final bool isTransfer;

  const _TransitLegData({
    required this.points,
    required this.color,
    required this.busNumber,
    required this.boardCoord,
    required this.boardName,
    required this.alightCoord,
    required this.alightName,
    required this.isTransfer,
  });

  LatLng get midpoint {
    if (points.isNotEmpty) {
      return points[points.length ~/ 2];
    }
    return LatLng(
      (boardCoord.latitude + alightCoord.latitude) / 2.0,
      (boardCoord.longitude + alightCoord.longitude) / 2.0,
    );
  }
}

class _SelectedPlaceInfo {
  final String title;
  final String subtitle;
  final String tag;
  final LatLng coord;
  final Color color;
  final IconData icon;

  const _SelectedPlaceInfo({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.coord,
    required this.color,
    required this.icon,
  });
}

class _NativeInteractiveMapView extends StatefulWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;
  final String? transitResultJson;
  final VoidCallback? onMapReady;

  const _NativeInteractiveMapView({
    super.key,
    required this.divId,
    required this.route,
    required this.isSatellite,
    required this.scope,
    required this.gpsLocation,
    required this.isDarkMode,
    this.transitResultJson,
    this.onMapReady,
  });

  @override
  State<_NativeInteractiveMapView> createState() => _NativeInteractiveMapViewState();
}

class _NativeInteractiveMapViewState extends State<_NativeInteractiveMapView> {
  late final MapController _mapController;
  bool _isMapReady = false;
  late bool _isSatellite;
  TransitGpsLocation? _gpsLocation;

  List<LatLng> _drivingPolylinePoints = [];
  List<_TransitLegData> _transitLegs = [];
  LatLng? _originCoord;
  LatLng? _destCoord;
  String _originName = '';
  String _destName = '';

  _SelectedPlaceInfo? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isSatellite = widget.isSatellite;
    _gpsLocation = widget.gpsLocation;

    _parseRouteData(widget.route, widget.transitResultJson);
    _registerNativeControls(widget.divId);
  }

  void _registerNativeControls(String divId) {
    NativeMapRegistry.register(
      divId,
      NativeMapControllerEntry(
        onZoom: (delta) {
          if (!_isMapReady || !mounted) return;
          final currentZoom = _mapController.camera.zoom;
          final nextZoom = (currentZoom + delta).clamp(3.0, 19.0);
          _mapController.move(_mapController.camera.center, nextZoom);
        },
        onReset: () {
          if (!_isMapReady || !mounted) return;
          _fitRouteBounds();
        },
        onCenterGps: (lat, lng) {
          if (!_isMapReady || !mounted) return;
          _mapController.move(LatLng(lat, lng), 15.5);
        },
        onUpdateGps: (lat, lng) {
          if (!mounted) return;
          setState(() {
            _gpsLocation = TransitGpsLocation(
              latitude: lat,
              longitude: lng,
              accuracy: 5.0,
              timestamp: DateTime.now(),
            );
          });
        },
        onSetScope: (scope) {
          if (!mounted) return;
          _applyScope(scope);
        },
        onSetType: (isSat) {
          if (!mounted) return;
          setState(() => _isSatellite = isSat);
        },
        onUpdateRoute: (polylineEnc, oLat, oLng, dLat, dLng) {
          if (!mounted) return false;
          _updateRouteFromEnc(polylineEnc, oLat, oLng, dLat, dLng);
          return true;
        },
        onUpdateTransitRoute: (legsJson, {originLat, originLng, destLat, destLng}) {
          if (!mounted) return false;
          _updateTransitRouteFromJson(
            legsJson,
            oLat: originLat,
            oLng: originLng,
            dLat: destLat,
            dLng: destLng,
          );
          return true;
        },
        onClearRoute: () {
          if (!mounted) return;
          setState(() {
            _drivingPolylinePoints.clear();
            _transitLegs.clear();
            _selectedPlace = null;
          });
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _NativeInteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.divId != oldWidget.divId) {
      NativeMapRegistry.unregister(oldWidget.divId);
      _registerNativeControls(widget.divId);
    }

    if (widget.isSatellite != oldWidget.isSatellite) {
      setState(() => _isSatellite = widget.isSatellite);
    }

    if (widget.scope != oldWidget.scope && widget.scope != null) {
      if (_isMapReady) _applyScope(widget.scope!);
    }

    if (widget.gpsLocation != oldWidget.gpsLocation) {
      setState(() => _gpsLocation = widget.gpsLocation);
    }

    if (widget.route != oldWidget.route ||
        widget.transitResultJson != oldWidget.transitResultJson) {
      _parseRouteData(widget.route, widget.transitResultJson);
      if (_isMapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitRouteBounds();
        });
      }
    }
  }

  @override
  void dispose() {
    NativeMapRegistry.unregister(widget.divId);
    _mapController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    } else {
      fn();
    }
  }

  void _parseRouteData(TransitRouteResult? route, String? transitJson) {
    if (transitJson != null && transitJson.isNotEmpty) {
      _updateTransitRouteFromJson(
        transitJson,
        oLat: route?.originLat,
        oLng: route?.originLng,
        dLat: route?.destLat,
        dLng: route?.destLng,
        oName: route?.origin,
        dName: route?.destination,
      );
      return;
    }

    if (route != null) {
      _originName = route.origin;
      _destName = route.destination;
      _originCoord = LatLng(route.originLat, route.originLng);
      _destCoord = LatLng(route.destLat, route.destLng);

      if (route.encodedPolyline.isNotEmpty) {
        try {
          final decoded = GoogleDirectionsService.decodePolyline(route.encodedPolyline);
          _drivingPolylinePoints = decoded.map((c) => LatLng(c.latitude, c.longitude)).toList();
        } catch (_) {
          _drivingPolylinePoints = [
            LatLng(route.originLat, route.originLng),
            LatLng(route.destLat, route.destLng),
          ];
        }
      } else if (route.polylineCoordinates.isNotEmpty) {
        _drivingPolylinePoints =
            route.polylineCoordinates.map((c) => LatLng(c.latitude, c.longitude)).toList();
      } else {
        _drivingPolylinePoints = [];
      }
      _transitLegs = [];
      _safeSetState(() {});
    }
  }

  void _updateRouteFromEnc(
    String polylineEnc,
    double? oLat,
    double? oLng,
    double? dLat,
    double? dLng,
  ) {
    List<LatLng> points = [];
    if (polylineEnc.isNotEmpty) {
      try {
        final decoded = GoogleDirectionsService.decodePolyline(polylineEnc);
        points = decoded.map((c) => LatLng(c.latitude, c.longitude)).toList();
      } catch (_) {}
    }

    _safeSetState(() {
      _drivingPolylinePoints = points;
      _transitLegs = [];
      if (oLat != null && oLng != null) _originCoord = LatLng(oLat, oLng);
      if (dLat != null && dLng != null) _destCoord = LatLng(dLat, dLng);
    });

    if (_isMapReady) {
      _fitRouteBounds();
    }
  }

  void _updateTransitRouteFromJson(
    String jsonStr, {
    double? oLat,
    double? oLng,
    double? dLat,
    double? dLng,
    String? oName,
    String? dName,
  }) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final parsedLegs = <_TransitLegData>[];

      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          final enc = (raw['polylineEnc'] ?? '').toString();
          List<LatLng> pts = [];
          if (enc.isNotEmpty) {
            try {
              final decoded = GoogleDirectionsService.decodePolyline(enc);
              pts = decoded.map((c) => LatLng(c.latitude, c.longitude)).toList();
            } catch (_) {}
          }

          final colorHex = (raw['color'] ?? '#1A73E8').toString();
          final cleanColorHex = colorHex.replaceFirst('#', '');
          final colorInt = int.tryParse(cleanColorHex, radix: 16) ?? 0x1A73E8;
          final color = Color(0xFF000000 | colorInt);

          final boardLat = (raw['boardLat'] as num?)?.toDouble() ?? 0.0;
          final boardLng = (raw['boardLng'] as num?)?.toDouble() ?? 0.0;
          final alightLat = (raw['alightLat'] as num?)?.toDouble() ?? 0.0;
          final alightLng = (raw['alightLng'] as num?)?.toDouble() ?? 0.0;

          if (pts.isEmpty && boardLat != 0.0 && alightLat != 0.0) {
            pts = [LatLng(boardLat, boardLng), LatLng(alightLat, alightLng)];
          }

          parsedLegs.add(
            _TransitLegData(
              points: pts,
              color: color,
              busNumber: (raw['busNumber'] ?? '').toString(),
              boardCoord: LatLng(boardLat, boardLng),
              boardName: (raw['boardName'] ?? '').toString(),
              alightCoord: LatLng(alightLat, alightLng),
              alightName: (raw['alightName'] ?? '').toString(),
              isTransfer: raw['isTransfer'] == true,
            ),
          );
        }
      }

      _safeSetState(() {
        _transitLegs = parsedLegs;
        _drivingPolylinePoints = [];
        if (oLat != null && oLng != null) _originCoord = LatLng(oLat, oLng);
        if (dLat != null && dLng != null) _destCoord = LatLng(dLat, dLng);
        if (oName != null && oName.isNotEmpty) _originName = oName;
        if (dName != null && dName.isNotEmpty) _destName = dName;

        if (_originCoord == null && parsedLegs.isNotEmpty) {
          _originCoord = parsedLegs.first.boardCoord;
          _originName = parsedLegs.first.boardName;
        }
        if (_destCoord == null && parsedLegs.isNotEmpty) {
          _destCoord = parsedLegs.last.alightCoord;
          _destName = parsedLegs.last.alightName;
        }
      });

      if (_isMapReady) {
        _fitRouteBounds();
      }
    } catch (e) {
      debugPrint('[NativeMapView] Error parsing transit legs JSON: $e');
    }
  }

  void _applyScope(String scope) {
    if (scope == 'city') {
      _mapController.move(
        const LatLng(TransitMapConfig.ahmedabadCenterLat, TransitMapConfig.ahmedabadCenterLng),
        TransitMapConfig.cityScopeZoom.toDouble(),
      );
    } else if (scope == 'metro') {
      _mapController.move(
        const LatLng(TransitMapConfig.metroRegionCenterLat, TransitMapConfig.metroRegionCenterLng),
        TransitMapConfig.metroScopeZoom.toDouble(),
      );
    } else {
      _fitRouteBounds();
    }
  }

  void _fitRouteBounds() {
    if (!_isMapReady || !mounted) return;

    final allCoords = <LatLng>[];

    if (_drivingPolylinePoints.isNotEmpty) {
      allCoords.addAll(_drivingPolylinePoints);
    }
    for (final leg in _transitLegs) {
      allCoords.addAll(leg.points);
      allCoords.add(leg.boardCoord);
      allCoords.add(leg.alightCoord);
    }

    if (_originCoord != null) allCoords.add(_originCoord!);
    if (_destCoord != null) allCoords.add(_destCoord!);

    if (allCoords.isEmpty) {
      if (_gpsLocation != null) {
        _mapController.move(
          LatLng(_gpsLocation!.latitude, _gpsLocation!.longitude),
          14.0,
        );
      } else {
        _mapController.move(
          const LatLng(TransitMapConfig.ahmedabadCenterLat, TransitMapConfig.ahmedabadCenterLng),
          12.5,
        );
      }
      return;
    }

    if (allCoords.length == 1) {
      _mapController.move(allCoords.first, 15.0);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(allCoords);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          maxZoom: 16.5,
          minZoom: 11.0,
        ),
      );
    } catch (e) {
      debugPrint('[NativeMapView] Camera fit error: $e');
    }
  }

  double get _initialZoom {
    if (_originCoord != null && _destCoord != null) {
      final latDiff = (_originCoord!.latitude - _destCoord!.latitude).abs();
      final lngDiff = (_originCoord!.longitude - _destCoord!.longitude).abs();
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      if (maxDiff > 0.2) return 10.0;
      if (maxDiff > 0.1) return 11.0;
      if (maxDiff > 0.04) return 12.0;
      if (maxDiff > 0.02) return 13.0;
      return 14.0;
    }
    return 12.5;
  }

  LatLng get _initialCenter {
    if (_originCoord != null && _destCoord != null) {
      return LatLng(
        (_originCoord!.latitude + _destCoord!.latitude) / 2.0,
        (_originCoord!.longitude + _destCoord!.longitude) / 2.0,
      );
    }
    if (_originCoord != null) return _originCoord!;
    if (_gpsLocation != null) {
      return LatLng(_gpsLocation!.latitude, _gpsLocation!.longitude);
    }
    return const LatLng(TransitMapConfig.ahmedabadCenterLat, TransitMapConfig.ahmedabadCenterLng);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 3.0,
              maxZoom: 19.0,
              backgroundColor: _isSatellite ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, __) {
                if (_selectedPlace != null) {
                  setState(() => _selectedPlace = null);
                }
              },
              onMapReady: () {
                _isMapReady = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fitRouteBounds();
                });
                widget.onMapReady?.call();
              },
            ),
            children: [
              // 1. Google Maps Vector & Hybrid Tiles with CartoDB & OSM fallback
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                    : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                fallbackUrl: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pravha.transit_app',
                maxZoom: 19,
              ),

              // 2. Polyline Layer (Driving path or colored multimodal transit legs)
              PolylineLayer(
                polylines: _buildPolylines(),
              ),

              // 3. Marker Layer (Origin A, Destination B, Transfer pins, Route Badges, Live GPS)
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // 4. Interactive InfoWindow Card (Matching localhost popup experience)
          if (_selectedPlace != null)
            _buildSelectedPlaceCard(_selectedPlace!),
        ],
      ),
    );
  }

  Widget _buildSelectedPlaceCard(_SelectedPlaceInfo place) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: place.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(place.icon, color: place.color, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedPlace = null),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.accessible_rounded, size: 12, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          place.tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _mapController.move(place.coord, 16.0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Focus Stop',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Single driving route corridor
    if (_drivingPolylinePoints.isNotEmpty) {
      // Outer casing for contrast
      polylines.add(
        Polyline(
          points: _drivingPolylinePoints,
          strokeWidth: 8.0,
          color: const Color(0x550284C7),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
      // Inner vibrant line
      polylines.add(
        Polyline(
          points: _drivingPolylinePoints,
          strokeWidth: 5.0,
          color: const Color(0xFF2563EB),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    // Multimodal transit legs
    for (final leg in _transitLegs) {
      if (leg.points.isNotEmpty) {
        polylines.add(
          Polyline(
            points: leg.points,
            strokeWidth: 8.0,
            color: leg.color.withValues(alpha: 0.35),
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
        polylines.add(
          Polyline(
            points: leg.points,
            strokeWidth: 5.0,
            color: leg.color,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      }
    }

    return polylines;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Origin Marker (Pin A - Green)
    if (_originCoord != null) {
      markers.add(
        Marker(
          point: _originCoord!,
          width: 80,
          height: 60,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlace = _SelectedPlaceInfo(
                  title: _originName.isNotEmpty ? _originName : 'Origin Point (Stop A)',
                  subtitle: 'Boarding Station • Ahmedabad Transit Corridor',
                  tag: 'Accessible Boarding Station',
                  coord: _originCoord!,
                  color: const Color(0xFF10B981),
                  icon: Icons.trip_origin_rounded,
                );
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_originName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xF00F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      _originName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Destination Marker (Pin B - Red)
    if (_destCoord != null) {
      markers.add(
        Marker(
          point: _destCoord!,
          width: 80,
          height: 60,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlace = _SelectedPlaceInfo(
                  title: _destName.isNotEmpty ? _destName : 'Destination (Stop B)',
                  subtitle: 'Thaltej, Ahmedabad, Gujarat • Transit Terminus',
                  tag: 'Accessible entrance',
                  coord: _destCoord!,
                  color: const Color(0xFFEF4444),
                  icon: Icons.location_on_rounded,
                );
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_destName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xF00F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      _destName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Transit Transfer Markers
    for (int i = 1; i < _transitLegs.length; i++) {
      final leg = _transitLegs[i];
      markers.add(
        Marker(
          point: leg.boardCoord,
          width: 72,
          height: 48,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlace = _SelectedPlaceInfo(
                  title: leg.boardName,
                  subtitle: 'Interchange Station • Transfer to Bus ${leg.busNumber}',
                  tag: 'Transfer Station',
                  coord: leg.boardCoord,
                  color: const Color(0xFF0284C7),
                  icon: Icons.transfer_within_a_station_rounded,
                );
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xEE0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.transfer_within_a_station_rounded, size: 10, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 3),
                      Text(
                        leg.busNumber,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Floating Bus Route Badges along Polyline (matching Google Maps web experience)
    for (final leg in _transitLegs) {
      if (leg.busNumber.isNotEmpty) {
        markers.add(
          Marker(
            point: leg.midpoint,
            width: 58,
            height: 32,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlace = _SelectedPlaceInfo(
                    title: 'Bus Route ${leg.busNumber}',
                    subtitle: '${leg.boardName} → ${leg.alightName}',
                    tag: 'Live Transit Line',
                    coord: leg.midpoint,
                    color: leg.color,
                    icon: Icons.directions_bus_rounded,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: leg.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus_rounded, size: 11, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      leg.busNumber,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // Live GPS Marker (Pulsing Cyan)
    if (_gpsLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_gpsLocation!.latitude, _gpsLocation!.longitude),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x3300E5FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x8800E5FF),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xAA00E5FF),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }
}

