/// Route Polyline Slicer — this is the layer that sits between the raw GTFS
/// route geometry and the Google Maps SDK.
///
/// Google Maps has no built-in idea of "just show me the part of route 9U
/// between these two stops." A Polyline widget draws whatever coordinate
/// list you hand it. So to show only the ridden portion of a bus's route,
/// you must precompute the clipped coordinate list yourself, BEFORE it
/// reaches the map widget. That's exactly what this file does.
///
/// Algorithm:
///   1. Project the board stop and alight stop onto the route's full shape
///      (perpendicular projection onto the nearest shape segment).
///   2. Walk the shape's points between those two projections, in the
///      direction the rider actually travels (handles shapes stored in
///      either direction).
///   3. Return that sub-list as the only geometry the UI ever sees for
///      this leg.
library route_polyline_slicer;

import '../models/transit_graph_models.dart';

class _Projection {
  final double cumulativeDistanceM;
  final LatLon point;
  const _Projection(this.cumulativeDistanceM, this.point);
}

class RoutePolylineSlicer {
  /// Cumulative distance (m) at each point of [points], point[0] == 0.
  static List<double> _buildCumulative(List<LatLon> points) {
    final cum = <double>[0];
    for (int i = 1; i < points.length; i++) {
      final d = GeoMath.haversineM(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
      cum.add(cum.last + d);
    }
    return cum;
  }

  /// Finds the closest point ON the polyline to [targetLat]/[targetLon].
  static _Projection _projectOntoShape(
    List<LatLon> points,
    List<double> cum,
    double targetLat,
    double targetLon,
  ) {
    final origin = points.first;
    final t = GeoMath.localXY(origin.lat, origin.lon, targetLat, targetLon);
    final tx = t[0], ty = t[1];

    double bestDistSq = double.infinity;
    double bestCum = 0;
    LatLon bestPoint = origin;

    for (int i = 0; i < points.length - 1; i++) {
      final a = GeoMath.localXY(
        origin.lat,
        origin.lon,
        points[i].lat,
        points[i].lon,
      );
      final b = GeoMath.localXY(
        origin.lat,
        origin.lon,
        points[i + 1].lat,
        points[i + 1].lon,
      );
      final dx = b[0] - a[0], dy = b[1] - a[1];
      final segLenSq = dx * dx + dy * dy;
      double frac;
      if (segLenSq == 0) {
        frac = 0;
      } else {
        frac = (((tx - a[0]) * dx) + ((ty - a[1]) * dy)) / segLenSq;
        if (frac < 0) frac = 0;
        if (frac > 1) frac = 1;
      }
      final px = a[0] + frac * dx, py = a[1] + frac * dy;
      final distSq = (tx - px) * (tx - px) + (ty - py) * (ty - py);
      if (distSq < bestDistSq) {
        bestDistSq = distSq;
        bestCum = cum[i] + (frac * (cum[i + 1] - cum[i]));
        bestPoint = LatLon(
          points[i].lat + frac * (points[i + 1].lat - points[i].lat),
          points[i].lon + frac * (points[i + 1].lon - points[i].lon),
        );
      }
    }
    return _Projection(bestCum, bestPoint);
  }

  /// Returns ONLY the points of [shape] that lie between [boardStop] and
  /// [alightStop], oriented in the direction the rider actually travels.
  /// This — not the full shape — is what should be handed to the map widget.
  static List<LatLon> sliceForLeg({
    required RouteShape shape,
    required Stop boardStop,
    required Stop alightStop,
  }) {
    if (shape.points.length < 2) return List.of(shape.points);

    final cum = _buildCumulative(shape.points);
    final boardProj = _projectOntoShape(
      shape.points,
      cum,
      boardStop.lat,
      boardStop.lon,
    );
    final alightProj = _projectOntoShape(
      shape.points,
      cum,
      alightStop.lat,
      alightStop.lon,
    );

    final reversed =
        boardProj.cumulativeDistanceM > alightProj.cumulativeDistanceM;
    final lo = reversed
        ? alightProj.cumulativeDistanceM
        : boardProj.cumulativeDistanceM;
    final hi = reversed
        ? boardProj.cumulativeDistanceM
        : alightProj.cumulativeDistanceM;

    final sliced = <LatLon>[reversed ? alightProj.point : boardProj.point];
    for (int i = 0; i < cum.length; i++) {
      if (cum[i] > lo && cum[i] < hi) {
        sliced.add(shape.points[i]);
      }
    }
    sliced.add(reversed ? boardProj.point : alightProj.point);

    return reversed ? sliced.reversed.toList() : sliced;
  }
}
