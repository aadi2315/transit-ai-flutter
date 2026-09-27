/// Global registry connecting native platform map controls with UI buttons
/// (Zoom in/out, Recenter, Live GPS, Scope, Map type, Route updates)
class NativeMapControllerEntry {
  final void Function(int delta)? onZoom;
  final void Function()? onReset;
  final void Function(double lat, double lng)? onCenterGps;
  final void Function(double lat, double lng)? onUpdateGps;
  final void Function(String scope)? onSetScope;
  final void Function(bool isSatellite)? onSetType;
  final bool Function(
    String polylineEnc,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
  )? onUpdateRoute;
  final bool Function(
    String legsJson, {
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
  })? onUpdateTransitRoute;
  final void Function()? onClearRoute;

  const NativeMapControllerEntry({
    this.onZoom,
    this.onReset,
    this.onCenterGps,
    this.onUpdateGps,
    this.onSetScope,
    this.onSetType,
    this.onUpdateRoute,
    this.onUpdateTransitRoute,
    this.onClearRoute,
  });
}

class NativeMapRegistry {
  static final Map<String, NativeMapControllerEntry> _entries = {};

  static void register(String divId, NativeMapControllerEntry entry) {
    _entries[divId] = entry;
  }

  static void unregister(String divId) {
    _entries.remove(divId);
  }

  static void zoom(String divId, int delta) {
    _entries[divId]?.onZoom?.call(delta);
  }

  static void reset(String divId) {
    _entries[divId]?.onReset?.call();
  }

  static void centerGps(String divId, double lat, double lng) {
    _entries[divId]?.onCenterGps?.call(lat, lng);
  }

  static void updateGps(String divId, double lat, double lng) {
    _entries[divId]?.onUpdateGps?.call(lat, lng);
  }

  static void setScope(String divId, String scope) {
    _entries[divId]?.onSetScope?.call(scope);
  }

  static void setType(String divId, bool isSatellite) {
    _entries[divId]?.onSetType?.call(isSatellite);
  }

  static bool updateRoute(
    String divId,
    String polylineEnc,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
  ) {
    return _entries[divId]?.onUpdateRoute?.call(
          polylineEnc,
          originLat,
          originLng,
          destLat,
          destLng,
        ) ??
        false;
  }

  static bool updateTransitRoute(
    String divId,
    String legsJson, {
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
  }) {
    return _entries[divId]?.onUpdateTransitRoute?.call(
          legsJson,
          originLat: originLat,
          originLng: originLng,
          destLat: destLat,
          destLng: destLng,
        ) ??
        false;
  }

  static void clearRoute(String divId) {
    _entries[divId]?.onClearRoute?.call();
  }
}
