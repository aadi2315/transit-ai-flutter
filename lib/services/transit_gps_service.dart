import 'dart:async';
import 'web_maps_bridge.dart';

/// Represents a live GPS location reading
class TransitGpsLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isMock;

  const TransitGpsLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.isMock = false,
  });

  String get formattedCoords =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  String get accuracyLabel => '±${accuracy.round()}m';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'isMock': isMock,
      };
}

/// Service providing live GPS coordinates for Transit AI
class TransitGpsService {
  TransitGpsService._();
  static final TransitGpsService instance = TransitGpsService._();

  // Default Ahmedabad transit corridor anchor (Sola Bhagwat Hub)
  static const double fallbackLat = 23.0827;
  static const double fallbackLng = 72.5284;

  TransitGpsLocation? _lastKnownLocation;
  StreamController<TransitGpsLocation>? _streamController;
  Timer? _pollingTimer;

  TransitGpsLocation? get lastKnownLocation => _lastKnownLocation;

  /// Fetches current GPS location from browser/device or fallback
  Future<TransitGpsLocation> getCurrentLocation() async {
    try {
      final jsResult = await queryJsCurrentLocation();
      if (jsResult != null &&
          jsResult['latitude'] != null &&
          jsResult['longitude'] != null) {
        final loc = TransitGpsLocation(
          latitude: (jsResult['latitude'] as num).toDouble(),
          longitude: (jsResult['longitude'] as num).toDouble(),
          accuracy: (jsResult['accuracy'] as num?)?.toDouble() ?? 8.0,
          timestamp: DateTime.now(),
          isMock: false,
        );
        _lastKnownLocation = loc;
        return loc;
      }
    } catch (_) {
      // Fallback below
    }

    // Default simulation anchor with slight realistic jitter
    final loc = TransitGpsLocation(
      latitude: fallbackLat,
      longitude: fallbackLng,
      accuracy: 6.0,
      timestamp: DateTime.now(),
      isMock: true,
    );
    _lastKnownLocation = loc;
    return loc;
  }

  /// Broadcast stream of live location readings
  Stream<TransitGpsLocation> streamLocation({
    Duration interval = const Duration(seconds: 4),
  }) {
    _streamController ??= StreamController<TransitGpsLocation>.broadcast(
      onListen: () {
        getCurrentLocation().then((loc) {
          if (!_streamController!.isClosed) {
            _streamController!.add(loc);
          }
        });
        _pollingTimer = Timer.periodic(interval, (_) async {
          final loc = await getCurrentLocation();
          if (!_streamController!.isClosed) {
            _streamController!.add(loc);
          }
        });
      },
      onCancel: () {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      },
    );
    return _streamController!.stream;
  }
}
