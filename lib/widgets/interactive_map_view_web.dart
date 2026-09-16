// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../services/google_directions_service.dart';
import '../services/transit_gps_service.dart';
import '../services/web_maps_bridge.dart';

import 'dart:js' as js;

final Set<String> _registeredViews = <String>{};

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
  return _WebInteractiveMapView(
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

class _WebInteractiveMapView extends StatefulWidget {
  final String divId;
  final TransitRouteResult? route;
  final bool isSatellite;
  final String? scope;
  final TransitGpsLocation? gpsLocation;
  final bool isDarkMode;
  final String? transitResultJson;
  final VoidCallback? onMapReady;

  const _WebInteractiveMapView({
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
  State<_WebInteractiveMapView> createState() => _WebInteractiveMapViewState();
}

class _WebInteractiveMapViewState extends State<_WebInteractiveMapView> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ensureViewRegistered(widget.divId);
    _initializeJsMap();
  }

  void _ensureViewRegistered(String id) {
    if (!_registeredViews.contains(id)) {
      _registeredViews.add(id);
      ui_web.platformViewRegistry.registerViewFactory(id, (int viewId) {
        final el = html.DivElement()
          ..id = id
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..style.outline = 'none'
          ..style.backgroundColor = '#f8fafc';
        try {
          if (js.context.hasProperty('transitRegisterElement')) {
            js.context.callMethod('transitRegisterElement', [id, el]);
          }
        } catch (_) {}
        return el;
      });
    }
  }

  void _initializeJsMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryInitMap(attempts: 0);
    });
  }

  void _tryInitMap({int attempts = 0}) {
    if (!mounted) return;
    final ok = initInteractiveMap(widget.divId, isSatellite: widget.isSatellite);
    if (ok) {
      _initialized = true;
      _syncAll();
      widget.onMapReady?.call();
    } else if (attempts < 16) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _tryInitMap(attempts: attempts + 1);
      });
    }
  }

  void _syncAll() {
    if (widget.transitResultJson != null && widget.transitResultJson!.isNotEmpty) {
      updateTransitRoute(
        widget.divId,
        widget.transitResultJson!,
        originLat: widget.route?.originLat,
        originLng: widget.route?.originLng,
        destLat: widget.route?.destLat,
        destLng: widget.route?.destLng,
      );
    } else {
      final r = widget.route;
      if (r != null) {
        updateInteractiveRoute(
          widget.divId,
          r.encodedPolyline,
          r.originLat,
          r.originLng,
          r.destLat,
          r.destLng,
        );
      }
    }
    if (widget.scope != null) {
      setInteractiveMapScope(widget.divId, widget.scope!);
    }
    if (widget.gpsLocation != null) {
      updateInteractiveGps(
        widget.divId,
        widget.gpsLocation!.latitude,
        widget.gpsLocation!.longitude,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _WebInteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_initialized) {
      _initializeJsMap();
      return;
    }

    if (widget.isSatellite != oldWidget.isSatellite) {
      setInteractiveMapType(widget.divId, widget.isSatellite);
    }

    if (widget.transitResultJson != oldWidget.transitResultJson &&
        widget.transitResultJson != null &&
        widget.transitResultJson!.isNotEmpty) {
      updateTransitRoute(
        widget.divId,
        widget.transitResultJson!,
        originLat: widget.route?.originLat,
        originLng: widget.route?.originLng,
        destLat: widget.route?.destLat,
        destLng: widget.route?.destLng,
      );
    } else if (widget.route != oldWidget.route && widget.route != null) {
      final r = widget.route!;
      updateInteractiveRoute(
        widget.divId,
        r.encodedPolyline,
        r.originLat,
        r.originLng,
        r.destLat,
        r.destLng,
      );
    }

    if (widget.scope != oldWidget.scope && widget.scope != null) {
      setInteractiveMapScope(widget.divId, widget.scope!);
    }

    if (widget.gpsLocation != oldWidget.gpsLocation && widget.gpsLocation != null) {
      updateInteractiveGps(
        widget.divId,
        widget.gpsLocation!.latitude,
        widget.gpsLocation!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: widget.divId,
    );
  }
}
