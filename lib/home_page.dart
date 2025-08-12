import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String text = "Start";
  List<String> locationHistory = [];
  bool isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check service status when app opens
    _checkServiceStatus();

    // Listen for location updates from the background service
    FlutterBackgroundService().on('locationUpdate').listen((event) {
      if (event != null && event['location'] != null) {
        setState(() {
          locationHistory.insert(0, event['location']);
          if (locationHistory.length > 50) {
            locationHistory.removeLast();
          }
        });
      }
    });
  }

  // Add this method to check service status and switch to background if app is open
  void _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      text = isRunning ? "Stop" : "Start";
    });

    // If service is running and app is open, switch to background mode
    if (isRunning && isAppInForeground) {
      service.invoke('setAsBackground');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    setState(() {
      isAppInForeground = state == AppLifecycleState.resumed;
    });

    // Check service status when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }

    // Auto-switch service mode based on app state
    _autoSwitchServiceMode();
  }

  void _autoSwitchServiceMode() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (isRunning) {
      if (isAppInForeground) {
        // App is open - use background service (no notification)
        service.invoke('setAsBackground');
      } else {
        // App is closed/minimized - use foreground service (with notification)
        service.invoke('setAsForeground');
      }
    }
  }

  Future<void> _startService() async {
    final service = FlutterBackgroundService();
    await service.startService();

    // Start in background mode if app is open, foreground if closed
    if (isAppInForeground) {
      service.invoke('setAsBackground');
    } else {
      service.invoke('setAsForeground');
    }

    setState(() {
      text = "Stop";
    });
  }

  Future<bool> _showBatteryOptimizationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To ensure the location service continues running when the app is closed, '
                'please disable battery optimization for this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Colors.blue,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                isAppInForeground ? 'App: Open' : 'App: Background',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main start/stop button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final service = FlutterBackgroundService();
                      bool isRunning = await service.isRunning();

                      if (isRunning) {
                        service.invoke("stopService");
                        setState(() {
                          text = "Start";
                        });
                      } else {
                        await _startService();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: text == "Stop" ? Colors.red : Colors.green,
                    ),
                    child: Text(
                      text == "Stop" ? "Stop Tracking" : "Start Tracking",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Auto Mode:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("• App Open: Background service (data in list)"),
                Text("• App Closed: Foreground service (notification)"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Clear button and history
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location History (${locationHistory.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      locationHistory.clear();
                    });
                  },
                  child: const Text("Clear"),
                ),
              ],
            ),
          ),

          const Divider(),

          // Location list
          Expanded(
            child: locationHistory.isEmpty
                ? const Center(
              child: Text(
                'No location data yet.\nClick "Start Tracking" to begin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: locationHistory.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    title: Text(
                      locationHistory[index],
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${locationHistory.length - index} entries ago',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}