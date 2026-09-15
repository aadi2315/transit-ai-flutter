import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/transit_map_config.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';

/// Authentic Interactive Google Maps View
///
/// Renders authentic Google Maps vector imagery with driving route polylines,
/// origin / destination markers, and live GPS.
/// Supports fluid 2D inertial panning, pinch-to-zoom, and programmatic zoom controls
/// via [TransformationController].
class InteractiveGoogleMapView extends StatefulWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;
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
    this.transformationController,
    this.onMapReady,
  });

  @override
  State<InteractiveGoogleMapView> createState() =>
      _InteractiveGoogleMapViewState();
}

class _InteractiveGoogleMapViewState extends State<InteractiveGoogleMapView> {
  late TransformationController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.transformationController != null) {
      _controller = widget.transformationController!;
      _ownsController = false;
    } else {
      _controller = TransformationController();
      _ownsController = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapReady?.call();
    });
  }

  @override
  void didUpdateWidget(covariant InteractiveGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transformationController != null &&
        widget.transformationController != _controller) {
      if (_ownsController) _controller.dispose();
      _controller = widget.transformationController!;
      _ownsController = false;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    if (route == null ||
        route.encodedPolyline.isEmpty ||
        !TransitMapConfig.hasGoogleMapsApiKey) {
      return _buildEmptyPlaceholder();
    }

    double? centerLat;
    double? centerLng;
    int? zoomLevel;

    if (widget.scope == 'city' || widget.scope == 'City Grid') {
      centerLat = TransitMapConfig.ahmedabadCenterLat;
      centerLng = TransitMapConfig.ahmedabadCenterLng;
      zoomLevel = TransitMapConfig.cityScopeZoom;
    } else if (widget.scope == 'metro' || widget.scope == 'Metro Wide') {
      centerLat = TransitMapConfig.metroRegionCenterLat;
      centerLng = TransitMapConfig.metroRegionCenterLng;
      zoomLevel = TransitMapConfig.metroScopeZoom;
    }

    final mapUrl = TransitMapConfig.buildStaticMapUrl(
      encodedPolyline: route.encodedPolyline,
      originLat: route.originLat,
      originLng: route.originLng,
      destLat: route.destLat,
      destLng: route.destLng,
      userLat: widget.gpsLocation?.latitude,
      userLng: widget.gpsLocation?.longitude,
      centerLat: centerLat,
      centerLng: centerLng,
      zoomLevel: zoomLevel,
      width: 768,
      height: 512,
      isDarkMode: false, // Authentic clean white Google Maps theme
      isSatellite: widget.isSatellite,
    );

    return ClipRect(
      child: Stack(
        children: [
          // 1. Fluid 2D Pan & Zoom Canvas
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _controller,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.6,
              maxScale: 4.5,
              child: Image.network(
                mapUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (ctx, err, stack) => _buildFallbackRoute(route),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: widget.isSatellite
                        ? const Color(0xFF0A1128)
                        : const Color(0xFFF8FAFC),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading Google Map...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Origin Stop Chip (Top-Left)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xF00F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x3310B981), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    route.origin,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Destination Stop Chip (Bottom-Left)
          Positioned(
            bottom: 22,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xF00F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x33EA4335), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA4335),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    route.destination,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Google Maps Footer (Pan freely description & attribution)
          Positioned(
            bottom: 4,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pan freely in 2D • Double-tap or buttons to zoom',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Google Maps',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      color: const Color(0xFF060E20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 36,
            color: Color(0xFF38BDF8),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter origin and destination to preview Google Maps route',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackRoute(TransitRouteResult route) {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route_rounded, size: 32, color: Color(0xFF38BDF8)),
          const SizedBox(height: 6),
          Text(
            '${route.origin} → ${route.destination}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${route.distanceKm.toStringAsFixed(1)} km • ${route.durationMins} mins',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: const Color(0xFF56E5A9),
            ),
          ),
        ],
      ),
    );
  }
}
