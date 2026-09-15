import 'package:flutter/material.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';
import '../config/transit_map_config.dart';

/// Platform implementation of interactive map for non-web environments (Flutter VM / tests)
Widget buildPlatformMapView({
  required Key? key,
  required String divId,
  required TransitRouteResult? route,
  required bool isSatellite,
  required String? scope,
  required TransitGpsLocation? gpsLocation,
  required bool isDarkMode,
  VoidCallback? onMapReady,
}) {
  return _StubMapView(
    key: key,
    divId: divId,
    route: route,
    isSatellite: isSatellite,
    scope: scope,
    gpsLocation: gpsLocation,
    isDarkMode: isDarkMode,
  );
}

class _StubMapView extends StatelessWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;

  const _StubMapView({
    super.key,
    required this.divId,
    required this.route,
    required this.isSatellite,
    required this.scope,
    required this.gpsLocation,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (route != null &&
        route!.encodedPolyline.isNotEmpty &&
        TransitMapConfig.hasGoogleMapsApiKey) {
      double? centerLat;
      double? centerLng;
      int? zoomLevel;
      if (scope == 'city') {
        centerLat = TransitMapConfig.ahmedabadCenterLat;
        centerLng = TransitMapConfig.ahmedabadCenterLng;
        zoomLevel = TransitMapConfig.cityScopeZoom;
      } else if (scope == 'metro') {
        centerLat = TransitMapConfig.metroRegionCenterLat;
        centerLng = TransitMapConfig.metroRegionCenterLng;
        zoomLevel = TransitMapConfig.metroScopeZoom;
      }

      return Container(
        color: const Color(0xFF0B1329),
        child: Image.network(
          TransitMapConfig.buildStaticMapUrl(
            encodedPolyline: route!.encodedPolyline,
            originLat: route!.originLat,
            originLng: route!.originLng,
            destLat: route!.destLat,
            destLng: route!.destLng,
            userLat: gpsLocation?.latitude,
            userLng: gpsLocation?.longitude,
            centerLat: centerLat,
            centerLng: centerLng,
            zoomLevel: zoomLevel,
            width: 640,
            height: 480,
            isDarkMode: isDarkMode,
            isSatellite: isSatellite,
          ),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0B1329),
      alignment: Alignment.center,
      child: const Icon(
        Icons.map_rounded,
        size: 32,
        color: Color(0xFF38BDF8),
      ),
    );
  }
}
