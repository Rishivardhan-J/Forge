import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofence_service/geofence_service.dart';
import '../models/habit.dart';

@pragma('vm:entry-point')
Future<void> _onGeofenceStatusChanged(
  Geofence geofence,
  GeofenceRadius geofenceRadius,
  GeofenceStatus geofenceStatus,
  Location location) async {

  if (geofenceStatus == GeofenceStatus.ENTER) {
    // Fire local notification
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

    await flutterLocalNotificationsPlugin.show(
      id: geofence.id.hashCode,
      title: 'You arrived at ${geofence.id}',
      body: 'Ready to show up? Remember, even the 2-min version counts.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'forge_habits_channel',
          'Habit Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

@pragma('vm:entry-point')
void _onLocationChanged(Location location) {}

@pragma('vm:entry-point')
void _onLocationServicesStatusChanged(bool status) {}

@pragma('vm:entry-point')
void _onActivityChanged(Activity prevActivity, Activity currActivity) {}

class GeofenceManager {
  static final GeofenceManager _instance = GeofenceManager._internal();
  factory GeofenceManager() => _instance;
  GeofenceManager._internal();

  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: kDebugMode,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC
  );

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);
    _isInitialized = true;
  }

  Future<void> updateGeofences(List<Habit> habits) async {
    await init();
    
    final geofences = <Geofence>[];
    for (final habit in habits) {
      if (habit.cueType == CueType.location && habit.notificationsEnabled && !habit.isArchived) {
        if (habit.cueLocationLat != null && habit.cueLocationLng != null) {
          geofences.add(
            Geofence(
              id: habit.name, // Using name for the notification message
              latitude: habit.cueLocationLat!,
              longitude: habit.cueLocationLng!,
              radius: [
                GeofenceRadius(id: 'radius_100m', length: habit.cueLocationRadius ?? 100.0),
              ],
            ),
          );
        }
      }
    }

    if (geofences.isEmpty) {
      await _geofenceService.stop();
      return;
    }

    // Start or update
    final isRunning = _geofenceService.isRunningService;
    if (isRunning) {
      // Just clear and add new
      for (final g in geofences) {
        _geofenceService.addGeofence(g);
      }
    } else {
      await _geofenceService.start(geofences);
    }
  }
}
