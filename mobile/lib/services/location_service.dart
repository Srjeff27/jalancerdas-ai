import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  /// Request location permissions
  Future<bool> requestPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services disabled');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('LocationService: Permission request failed: $e');
      return false;
    }
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return _currentPosition;
    } catch (e) {
      debugPrint('LocationService: Failed to get position: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startTracking({
    void Function(Position position)? onPositionUpdate,
    int distanceFilter = 5,
  }) async {
    if (_isTracking) return;

    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) return;

      _isTracking = true;

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (_currentPosition != null) {
        onPositionUpdate?.call(_currentPosition!);
      }

      // Start continuous tracking
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          timeLimit: const Duration(seconds: 5),
        ),
      ).listen(
        (Position position) {
          _currentPosition = position;
          onPositionUpdate?.call(position);
        },
        onError: (e) {
          debugPrint('LocationService: Stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('LocationService: Failed to start tracking: $e');
      _isTracking = false;
    }
  }

  /// Stop continuous tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void dispose() {
    stopTracking();
  }
}
