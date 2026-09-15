import 'package:flutter/material.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';
import 'interactive_map_view_stub.dart'
    if (dart.library.html) 'interactive_map_view_web.dart' as platform_map;

/// Universal Interactive Google Map Widget.
/// On Web: Renders a true Google Maps JavaScript SDK vector canvas via HtmlElementView,
/// supporting fluid inertial panning, vector zoom (revealing service roads, lanes, 3D buildings),
/// and dynamic polyline / markers.
/// On Non-Web / Test: Renders a safe fallback image or container.
class InteractiveGoogleMapView extends StatelessWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;
  final VoidCallback? onMapReady;

  const InteractiveGoogleMapView({
    super.key,
    required this.divId,
    required this.route,
    this.isSatellite = false,
    this.scope = 'corridor',
    this.gpsLocation,
    this.isDarkMode = true,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return platform_map.buildPlatformMapView(
      key: key,
      divId: divId,
      route: route,
      isSatellite: isSatellite,
      scope: scope,
      gpsLocation: gpsLocation,
      isDarkMode: isDarkMode,
      onMapReady: onMapReady,
    );
  }
}
