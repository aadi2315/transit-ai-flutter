/// Configuration and setup for Google Maps integration in Transit AI
class TransitMapConfig {
  /// Paste your Google Maps API Key here when ready:
  /// Example: 'AIzaSyYourActualGoogleMapsApiKeyHere'
  static String googleMapsApiKey = '';

  /// Returns true if a valid Google Maps API Key is configured
  static bool get hasGoogleMapsApiKey =>
      googleMapsApiKey.trim().isNotEmpty &&
      !googleMapsApiKey.contains('YOUR_') &&
      googleMapsApiKey.length > 15;

  /// Update the API key dynamically from UI or at runtime
  static void setApiKey(String key) {
    googleMapsApiKey = key.trim();
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
