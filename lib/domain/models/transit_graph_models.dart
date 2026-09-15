/// Core data models for the Multimodal Router + Map Slicing layer.
///
/// These map directly onto the Supabase schema:
///   gtfs_stops(stop_id, stop_name, latitude, longitude, transit_type)
///   gtfs_routes(route_id, route_short_name, operator, polyline_points)
///   gtfs_route_stops(route_id, stop_id, stop_sequence, travel_time_from_prev_mins, headway_mins)
library transit_graph_models;

import 'dart:math' as math;

/// A single physical bus stop / BRTS station.
class Stop {
  final String stopId;
  final String name;
  final double lat;
  final double lon;

  const Stop({
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lon,
  });

  factory Stop.fromSupabase(Map<String, dynamic> map) {
    return Stop(
      stopId: map['stop_id']?.toString() ?? '',
      name: map['stop_name']?.toString() ?? '',
      lat: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      lon: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stop_id': stopId,
        'stop_name': name,
        'latitude': lat,
        'longitude': lon,
      };

  @override
  String toString() => 'Stop($stopId, $name, $lat, $lon)';
}

/// The physical shape of a route (decoded from gtfs_routes.encoded_polyline or polyline_points).
class RouteShape {
  final String routeId;
  final List<LatLon> points;

  const RouteShape({required this.routeId, required this.points});
}

class LatLon {
  final double lat;
  final double lon;
  const LatLon(this.lat, this.lon);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lon};

  @override
  String toString() => 'LatLon($lat, $lon)';
}

/// The ordered list of stops a given route serves, in travel direction.
class RouteStopSequence {
  final String routeId;
  final String routeShortName;
  final List<String> stopIdsInOrder;
  final Map<String, int> travelTimeFromPrevMins;
  final int headwayMins;

  const RouteStopSequence({
    required this.routeId,
    required this.routeShortName,
    required this.stopIdsInOrder,
    this.travelTimeFromPrevMins = const {},
    this.headwayMins = 15,
  });
}

/// One rider-facing leg of a trip: "ride route X from stop A to stop B".
class TripLeg {
  final String routeId;
  final String routeShortName;
  final String boardStopId;
  final String alightStopId;
  final double estimatedSeconds;

  const TripLeg({
    required this.routeId,
    required this.routeShortName,
    required this.boardStopId,
    required this.alightStopId,
    this.estimatedSeconds = 0.0,
  });

  @override
  String toString() =>
      'TripLeg($routeShortName: $boardStopId -> $alightStopId)';
}

/// The full computed itinerary returned by the router, before map rendering.
class Itinerary {
  final List<TripLeg> legs;
  final double estimatedTotalSeconds;

  const Itinerary({required this.legs, required this.estimatedTotalSeconds});

  bool get requiresTransfer => legs.length > 1;

  double get estimatedTotalMinutes => estimatedTotalSeconds / 60.0;
}

/// Geometry helpers shared by the router and the polyline slicer.
class GeoMath {
  static const double earthRadiusM = 6371000.0;

  static double haversineM(double lat1, double lon1, double lat2, double lon2) {
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    return 2 * earthRadiusM * math.asin(math.sqrt(a));
  }

  /// Cheap equirectangular projection to local meters for route polyline slicing.
  static List<double> localXY(double originLat, double originLon, double lat, double lon) {
    final x = (lon - originLon) * math.pi / 180 * math.cos(originLat * math.pi / 180) * earthRadiusM;
    final y = (lat - originLat) * math.pi / 180 * earthRadiusM;
    return [x, y];
  }
}
