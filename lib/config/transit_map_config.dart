/// Configuration and setup for Google Maps integration in Transit AI
class TransitMapConfig {
  /// Google Maps API Key provided for Transit AI:
  static String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Returns true if a valid Google Maps API Key is configured
  static bool get hasGoogleMapsApiKey =>
      googleMapsApiKey.trim().isNotEmpty &&
      !googleMapsApiKey.contains('YOUR_') &&
      googleMapsApiKey.length > 15;

  /// Update the API key dynamically from UI or at runtime
  static void setApiKey(String key) {
    googleMapsApiKey = key.trim();
  }

  /// Builds a Google Directions API URL in DRIVING mode with intermediate transit waypoints
  static String buildDirectionsApiUrl({
    required String origin,
    required String destination,
    List<String>? waypoints,
  }) {
    final buffer = StringBuffer(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${Uri.encodeComponent(origin)}'
      '&destination=${Uri.encodeComponent(destination)}'
      '&mode=driving'
      '&key=$googleMapsApiKey',
    );
    if (waypoints != null && waypoints.isNotEmpty) {
      buffer.write('&waypoints=');
      buffer.write(waypoints.map((w) => Uri.encodeComponent(w)).join('|'));
    }
    return buffer.toString();
  }

  /// Builds a Google Static Maps image URL rendering the polyline path and endpoint markers
  static String buildStaticMapUrl({
    required String encodedPolyline,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    double? userLat,
    double? userLng,
    double? centerLat,
    double? centerLng,
    int? zoomLevel,
    int width = 640,
    int height = 640,
    bool isDarkMode = true,
    bool isSatellite = false,
  }) {
    final pathParam = encodedPolyline.isNotEmpty
        ? '&path=color:0x2563ebff|weight:6|enc:$encodedPolyline'
        : '';
    final markersBuffer = StringBuffer();
    if (originLat != null && originLng != null) {
      markersBuffer.write('&markers=color:0x10b981|label:A|$originLat,$originLng');
    }
    if (destLat != null && destLng != null) {
      markersBuffer.write('&markers=color:0xea4335|label:B|$destLat,$destLng');
    }
    if (userLat != null && userLng != null) {
      markersBuffer.write('&markers=color:0x00e5ff%7Csize:mid%7C$userLat,$userLng');
    }

    final centerParam = (centerLat != null && centerLng != null)
        ? '&center=$centerLat,$centerLng'
        : '';
    final zoomParam = zoomLevel != null ? '&zoom=$zoomLevel' : '';

    final mapTypeParam = isSatellite ? '&maptype=satellite' : '';
    final styleParam = (isDarkMode && !isSatellite)
        ? '&style=element:geometry%7Ccolor:0x1d2c4d&style=element:labels.text.fill%7Ccolor:0x8ec3b9&style=element:labels.text.stroke%7Ccolor:0x1a3646&style=feature:administrative.country%7Celement:geometry.stroke%7Ccolor:0x4b6878&style=feature:road%7Celement:geometry%7Ccolor:0x304a7d&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x98a5be&style=feature:water%7Celement:geometry%7Ccolor:0x0e1626'
        : '';

    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'size=${width}x$height'
        '&scale=2'
        '$centerParam'
        '$zoomParam'
        '$mapTypeParam'
        '$pathParam'
        '${markersBuffer.toString()}'
        '$styleParam'
        '&key=$googleMapsApiKey';
  }

  /// Default Ahmedabad / GIFT City Corridor Coordinates
  static const double defaultOriginLat = 23.0827; // Sola Bhagwat BRTS Hub
  static const double defaultOriginLng = 72.5284;

  static const double defaultDestLat = 23.0315; // Iskcon Cross Road
  static const double defaultDestLng = 72.5074;

  static const double kalupurStationLat = 23.0298; // Kalupur Metro Interchange
  static const double kalupurStationLng = 72.6010;

  static const double giftCityLat = 23.1610; // GIFT City Center
  static const double giftCityLng = 72.6841;

  /// Geographic City & Metro Center Points
  static const double ahmedabadCenterLat = 23.0338;
  static const double ahmedabadCenterLng = 72.5850;
  static const int cityScopeZoom = 12;

  static const double metroRegionCenterLat = 23.1000;
  static const double metroRegionCenterLng = 72.6000;
  static const int metroScopeZoom = 11;

  /// Instructions for activating Google Maps in Flutter:
  /// 1. Put your API key in [googleMapsApiKey] above or in the Route screen settings dialog.
  /// 2. For Flutter Web: In `web/index.html` inside `<head>`, uncomment:
  ///    `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>`
  /// 3. For Android: In `android/app/src/main/AndroidManifest.xml` inside `<application>`:
  ///    `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>`
  /// 4. For iOS: In `ios/Runner/AppDelegate.swift`:
  ///    `GMSServices.provideAPIKey("YOUR_KEY")`
  static const String setupInstructions = '''
To activate Google Maps in Transit AI:
1. Obtain an API key from the Google Cloud Console (Maps JavaScript API / Maps SDK for Android & iOS).
2. Set your key in TransitMapConfig.googleMapsApiKey.
3. For Web: In web/index.html, uncomment the Google Maps JS script tag.
4. For Android: Add com.google.android.geo.API_KEY meta-data in AndroidManifest.xml.
''';
}
