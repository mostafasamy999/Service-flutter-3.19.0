import 'package:flutter/material.dart';
import 'package:untitled3/permission_handler.dart';
import 'back_services.dart';
import 'home_page.dart';
// adb uninstall com.example.untitled3
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(const MyApp());
}

/// Initialize all app requirements before starting
Future<void> _initializeApp() async {
  // Request permissions
  await PermissionService.requestNotificationPermission();
  final locationResult = await PermissionService.requestLocationPermissions();

  // Log permission status
  debugPrint('🔐 Permission Status: ${locationResult.message}');

  // Initialize background service
  await initializeService();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}