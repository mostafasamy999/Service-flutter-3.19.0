import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true, // Change to true for better persistence
      autoStart: false, // Add these for better persistence
      initialNotificationTitle: 'Location Tracker',
      initialNotificationContent: 'Tracking your location...',
      foregroundServiceNotificationId: 888,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      // Get current location and time
      String locationTime = await getCurrentLocationTime();

      if (await service.isForegroundService()) {
        // Show location and time in notification when in foreground
        service.setForegroundNotificationInfo(
          title: "Location Tracker Active",
          content: locationTime,
        );
      } else {
        // Send location data to UI instead of printing
        service.invoke('locationUpdate', {
          'location': locationTime,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }

    service.invoke('update');
  });
}

Future<String> getCurrentLocationTime() async {
  try {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Location permission denied - ${DateTime.now().toString().substring(0, 19)}";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Location permanently denied - ${DateTime.now().toString().substring(0, 19)}";
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );

    // Format current time (HH:MM:SS)
    String currentTime = DateTime.now().toString().substring(11, 19);

    // Format location
    String lat = position.latitude.toStringAsFixed(6);
    String lng = position.longitude.toStringAsFixed(6);

    return "Time: $currentTime - Lat: ${lat.substring(0,7)}, Lng: ${lng.substring(0,7)}";

  } catch (e) {
    // If location fails, still show time
    String currentTime = DateTime.now().toString().substring(11, 19);
    return "Location unavailable - $currentTime";
  }
}