import 'package:flutter/material.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';

// Conditional import: real JS Google Maps on web, static-map fallback on VM/tests.
import 'interactive_map_view_stub.dart'
    if (dart.library.html) 'interactive_map_view_web.dart';



/// Authentic Interactive Google Maps View
///
/// On web: delegates to the real Google Maps JavaScript SDK via
/// [buildPlatformMapView] so the map fully supports native pan, pinch-zoom,
/// scroll-zoom, and double-tap — without any Flutter InteractiveViewer
/// fighting those gestures.
///
/// On native/tests: falls back to the stub (static image).
class InteractiveGoogleMapView extends StatefulWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;
  // Kept for API compatibility — no longer used (real map handles pan natively)
  final TransformationController? transformationController;
  final VoidCallback? onMapReady;

  const InteractiveGoogleMapView({
    super.key,
    required this.divId,
    required this.route,
    this.isSatellite = false,
    this.scope = 'corridor',
    this.gpsLocation,
    this.isDarkMode = false,
    this.transformationController, // kept for API compat, not used
    this.onMapReady,
  });

  @override
  State<InteractiveGoogleMapView> createState() =>
      _InteractiveGoogleMapViewState();
}

class _InteractiveGoogleMapViewState extends State<InteractiveGoogleMapView> {
  @override
  Widget build(BuildContext context) {
    // Delegate entirely to the platform-specific implementation.
    // On web this is the real Google Maps JS SDK (full pan/zoom).
    // On VM this is the static map image fallback.
    return buildPlatformMapView(
      key: widget.key,
      divId: widget.divId,
      route: widget.route,
      isSatellite: widget.isSatellite,
      scope: widget.scope,
      gpsLocation: widget.gpsLocation,
      isDarkMode: widget.isDarkMode,
      onMapReady: widget.onMapReady,
    );
  }
}
