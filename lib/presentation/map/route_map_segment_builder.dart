/// This is the actual "layer between the Google Maps API key and the screen".
///
/// Nothing here calls the Maps SDK directly — it just decides, precisely,
/// which coordinates and markers the map widget is allowed to draw. The
/// map view renders what comes out of `buildDisplaySegments`, never a
/// route's raw full-length shape.
library route_map_segment_builder;

import '../../domain/models/transit_graph_models.dart';
import '../../domain/engines/route_polyline_slicer.dart';

/// One color per leg so the rider can visually tell "this is the 9U part"
/// from "this is the 8D part" — cycles through if a trip has multiple legs.
const List<int> legColorsArgb = [
  0xFF1A73E8, // Google-blue
  0xFFEA4335, // red
  0xFF34A853, // green
  0xFFFBBC05, // amber
];

class MapMarker {
  final String label;
  final LatLon position;
  final bool isTransferPoint;
  const MapMarker({
    required this.label,
    required this.position,
    this.isTransferPoint = false,
  });
}

/// Everything the map widget needs to draw ONE leg of the trip: the clipped
/// polyline (not the full route shape) plus its board/alight markers.
class MapDisplaySegment {
  final String routeShortName;
  final int colorArgb;
  final List<LatLon> polyline; // <-- clipped, rider-relevant portion only
  final MapMarker boardMarker;
  final MapMarker alightMarker;

  const MapDisplaySegment({
    required this.routeShortName,
    required this.colorArgb,
    required this.polyline,
    required this.boardMarker,
    required this.alightMarker,
  });
}

class RouteMapSegmentBuilder {
  /// Converts a computed [Itinerary] into the exact set of polylines and
  /// markers the map should render — one clipped segment per leg, plus a
  /// distinct marker at every transfer point.
  static List<MapDisplaySegment> buildDisplaySegments({
    required Itinerary itinerary,
    required Map<String, Stop> stopsById,
    required Map<String, RouteShape> shapesByRouteId,
  }) {
    final segments = <MapDisplaySegment>[];

    for (int i = 0; i < itinerary.legs.length; i++) {
      final leg = itinerary.legs[i];
      final shape = shapesByRouteId[leg.routeId];
      final boardStop = stopsById[leg.boardStopId];
      final alightStop = stopsById[leg.alightStopId];

      if (boardStop == null || alightStop == null) continue;

      final clipped = shape == null
          ? <LatLon>[
              LatLon(boardStop.lat, boardStop.lon),
              LatLon(alightStop.lat, alightStop.lon),
            ]
          : RoutePolylineSlicer.sliceForLeg(
              shape: shape,
              boardStop: boardStop,
              alightStop: alightStop,
            );

      final isTransferBoard = i > 0; // arriving here via a transfer
      final isTransferAlight = i < itinerary.legs.length - 1; // will transfer here

      segments.add(MapDisplaySegment(
        routeShortName: leg.routeShortName,
        colorArgb: legColorsArgb[i % legColorsArgb.length],
        polyline: clipped,
        boardMarker: MapMarker(
          label: boardStop.name,
          position: LatLon(boardStop.lat, boardStop.lon),
          isTransferPoint: isTransferBoard,
        ),
        alightMarker: MapMarker(
          label: alightStop.name,
          position: LatLon(alightStop.lat, alightStop.lon),
          isTransferPoint: isTransferAlight,
        ),
      ));
    }

    return segments;
  }
}
