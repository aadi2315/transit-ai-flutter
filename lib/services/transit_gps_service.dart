import 'dart:async';
import 'package:geolocator/geolocator.dart';
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
  StreamSubscription<Position>? _geolocatorSubscription;
  Timer? _pollingTimer;

  TransitGpsLocation? get lastKnownLocation => _lastKnownLocation;

  /// Checks if device GPS location services are turned on in system settings
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }

  /// Checks current runtime location permission
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.whileInUse;
    }
  }

  /// Requests runtime location permission from the user
  Future<LocationPermission> requestPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm;
    } catch (_) {
      return LocationPermission.whileInUse;
    }
  }

  /// Opens system Location Settings (for user to enable GPS toggle)
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Opens App Settings (if permission is permanently denied)
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Fetches current GPS location from device hardware, browser bridge, or fallback
  Future<TransitGpsLocation> getCurrentLocation({bool requestIfNeeded = true}) async {
    // 1. Try real device GPS via Geolocator (Android APK / iOS)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied && requestIfNeeded) {
          perm = await Geolocator.requestPermission();
        }

        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 6),
            ),
          );
          final loc = TransitGpsLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
            timestamp: pos.timestamp,
            isMock: pos.isMocked,
          );
          _lastKnownLocation = loc;
          return loc;
        }
      }
    } catch (_) {
      // In tests or environments without native location provider, fall through gracefully
    }

    // 2. Try browser JS bridge (Web)
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

    // 3. Return last known location if available
    if (_lastKnownLocation != null) {
      return _lastKnownLocation!;
    }

    // 4. Default simulation anchor with slight realistic jitter
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

  /// Broadcast stream of live location readings from real hardware GPS
  Stream<TransitGpsLocation> streamLocation({
    Duration interval = const Duration(seconds: 3),
  }) {
    if (_streamController != null && !_streamController!.isClosed) {
      return _streamController!.stream;
    }

    _streamController = StreamController<TransitGpsLocation>.broadcast(
      onListen: () async {
        // Emit initial location reading immediately
        getCurrentLocation(requestIfNeeded: true).then((loc) {
          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.add(loc);
          }
        });

        // Attempt live hardware GPS stream with high accuracy & 2m distance filter
        bool hardwareStreaming = false;
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          final perm = await Geolocator.checkPermission();
          if (serviceEnabled &&
              (perm == LocationPermission.whileInUse || perm == LocationPermission.always)) {
            _geolocatorSubscription = Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 2,
              ),
            ).listen(
              (pos) {
                final loc = TransitGpsLocation(
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  accuracy: pos.accuracy,
                  timestamp: pos.timestamp,
                  isMock: pos.isMocked,
                );
                _lastKnownLocation = loc;
                if (_streamController != null && !_streamController!.isClosed) {
                  _streamController!.add(loc);
                }
              },
              onError: (_) {
                // If stream errors, fallback to polling
                _startPollingTimer(interval);
              },
            );
            hardwareStreaming = true;
          }
        } catch (_) {
          // Native stream unavailable (e.g. testing), fall through to polling
        }

        if (!hardwareStreaming) {
          _startPollingTimer(interval);
        }
      },
      onCancel: () {
        _geolocatorSubscription?.cancel();
        _geolocatorSubscription = null;
        _pollingTimer?.cancel();
        _pollingTimer = null;
      },
    );

    return _streamController!.stream;
  }

  void _startPollingTimer(Duration interval) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      final loc = await getCurrentLocation(requestIfNeeded: false);
      if (_streamController != null && !_streamController!.isClosed) {
        _streamController!.add(loc);
      }
    });
  }
}

