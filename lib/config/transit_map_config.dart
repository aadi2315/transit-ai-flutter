/// Configuration and setup for Google Maps integration in Transit AI
class TransitMapConfig {
  /// Paste your Google Maps API Key here when ready:
  /// Example: 'AIzaSyYourActualGoogleMapsApiKeyHere'
  static const String googleMapsApiKey = '';

  /// Returns true if a valid Google Maps API Key is configured
  static bool get hasGoogleMapsApiKey =>
      googleMapsApiKey.trim().isNotEmpty &&
      !googleMapsApiKey.contains('YOUR_') &&
      googleMapsApiKey.length > 10;

  /// Default Ahmedabad / GIFT City Corridor Coordinates
  static const double defaultOriginLat = 23.0827; // Sola Bhagwat BRTS
  static const double defaultOriginLng = 72.5284;

  static const double defaultDestLat = 23.0315; // Iskcon Cross Road
  static const double defaultDestLng = 72.5074;

  static const double giftCityLat = 23.1610; // GIFT City Center
  static const double giftCityLng = 72.6841;

  /// Instructions for activating Google Maps in Flutter Web:
  /// 1. Put your API key in [googleMapsApiKey] above.
  /// 2. Add the script in `web/index.html` inside <head>:
  ///    <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY"></script>
}
