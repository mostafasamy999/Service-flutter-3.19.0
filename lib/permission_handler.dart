import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class to handle all permission-related operations
class PermissionService {
  /// Request notification permission for background service
  static Future<bool> requestNotificationPermission() async {
    try {
      final isNotificationDenied = await Permission.notification.isDenied;

      if (isNotificationDenied) {
        final status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      }

      return true; // Already granted
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request location permissions (basic and background)
  static Future<LocationPermissionResult> requestLocationPermissions() async {
    try {
      // Request basic location permission first
      final locationStatus = await Permission.location.request();

      if (locationStatus != PermissionStatus.granted) {
        return LocationPermissionResult(
          hasLocation: false,
          hasBackgroundLocation: false,
          message: _getLocationErrorMessage(locationStatus),
        );
      }

      // Request background location permission
      final backgroundStatus = await Permission.locationAlways.request();

      return LocationPermissionResult(
        hasLocation: true,
        hasBackgroundLocation: backgroundStatus == PermissionStatus.granted,
        message: _getBackgroundLocationMessage(backgroundStatus),
      );

    } catch (e) {
      debugPrint('Error requesting location permissions: $e');
      return LocationPermissionResult(
        hasLocation: false,
        hasBackgroundLocation: false,
        message: 'Failed to request permissions: $e',
      );
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final notificationGranted = await Permission.notification.isGranted;
    final locationGranted = await Permission.location.isGranted;
    final backgroundLocationGranted = await Permission.locationAlways.isGranted;

    return notificationGranted && locationGranted && backgroundLocationGranted;
  }

  /// Open app settings for manual permission configuration
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  static String _getLocationErrorMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return 'Location permission denied';
      case PermissionStatus.permanentlyDenied:
        return 'Location permission permanently denied. Please enable in settings';
      case PermissionStatus.restricted:
        return 'Location permission restricted';
      default:
        return 'Location permission error: $status';
    }
  }

  static String _getBackgroundLocationMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'All permissions granted';
      case PermissionStatus.denied:
        return 'Background location denied. App will work with limitations';
      case PermissionStatus.permanentlyDenied:
        return 'Background location permanently denied. Please enable in settings';
      default:
        return 'Background location status: $status';
    }
  }
}

/// Result class for location permission requests
class LocationPermissionResult {
  final bool hasLocation;
  final bool hasBackgroundLocation;
  final String message;

  LocationPermissionResult({
    required this.hasLocation,
    required this.hasBackgroundLocation,
    required this.message,
  });

  bool get isFullyGranted => hasLocation && hasBackgroundLocation;
  bool get canTrackLocation => hasLocation;
}