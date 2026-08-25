import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:isar/isar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:path_provider/path_provider.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/identity.dart';
import '../models/user_settings.dart';
import '../utils/habit_utils.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.payload != null) {
    final payload = notificationResponse.payload!;
    // Payload format: "action|habitId|dateIso8601"
    final parts = payload.split('|');
    if (parts.length == 3) {
      final action = parts[0];
      final habitIdStr = parts[1];
      final dateStr = parts[2];
      
      final habitId = int.tryParse(habitIdStr);
      final date = DateTime.tryParse(dateStr);
      
      if (habitId != null && date != null) {
        final dir = await getApplicationDocumentsDirectory();
        final isar = await Isar.open(
          [HabitSchema, HabitLogSchema, IdentitySchema, UserSettingsSchema],
          directory: dir.path,
        );

        LogStatus status = LogStatus.done;
        if (action == 'twoMinute') {
          status = LogStatus.doneViaTwoMinute;
        }

        // Write log
        await isar.writeTxn(() async {
          final log = await isar.habitLogs.filter()
              .habitIdEqualTo(habitId.toString())
              .dateEqualTo(date)
              .findFirst();
          
          if (log != null) {
            log.status = status;
            await isar.habitLogs.put(log);
          } else {
            final newLog = HabitLog()
              ..habitId = habitId.toString()
              ..date = date
              ..status = status;
            await isar.habitLogs.put(newLog);
          }
        });

        // Cancel the notification since we've handled it
        final service = NotificationService();
        service.cancelHabitRemindersForToday(habitId.toString(), date);
      }
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Foreground tap can just navigate or handle if needed
        // For simplicity, we just handle background and let foreground tap open the app normally
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // Id derivation
  int _generateId(String habitId, DateTime date) {
    final str = '${habitId}_${date.year}_${date.month}_${date.day}';
    return str.hashCode;
  }
  
  int _generateWeeklyReviewId() {
    return 'weekly_review'.hashCode;
  }

  Future<void> scheduleHabitReminders(Habit habit) async {
    if (!habit.notificationsEnabled) {
      await cancelAllRemindersForHabit(habit.id.toString());
      return;
    }

    if (habit.cueType == CueType.time) {
      // Parse time cueValue (expected "HH:mm")
      final parts = habit.cueValue.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Schedule for the next 14 days (or so)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Cancel existing to overwrite
      await cancelAllRemindersForHabit(habit.id.toString());

      for (int i = 0; i < 14; i++) {
        final scheduleDate = today.add(Duration(days: i));
        
        // Skip if not scheduled for this day
        if (!HabitUtils.isScheduledOn(habit, scheduleDate)) {
          continue;
        }

        var scheduledTzDate = tz.TZDateTime.local(scheduleDate.year, scheduleDate.month, scheduleDate.day, hour, minute);
        
        // If it's today but in the past, skip
        if (scheduledTzDate.isBefore(tz.TZDateTime.now(tz.local))) {
          continue;
        }

        final id = _generateId(habit.id.toString(), scheduleDate);
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: 'Time for ${habit.name}',
          body: 'Even just ${habit.twoMinuteVersion} counts.',
          scheduledDate: scheduledTzDate,
          notificationDetails: _notificationDetails(habit.id.toString(), scheduleDate),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> cancelAllRemindersForHabit(String habitId) async {
    // This is tricky because we generate IDs based on dates.
    // The easiest way is to cancel for the next 14 days, since we only schedule 14 days out.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 14; i++) {
      final date = today.add(Duration(days: i));
      final id = _generateId(habitId, date);
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    }
  }

  Future<void> cancelHabitRemindersForToday(String habitId, DateTime date) async {
    final id = _generateId(habitId, date);
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> triggerAfterHabitNotification(Habit dependentHabit) async {
    if (!dependentHabit.notificationsEnabled) return;

    final now = DateTime.now();
    final id = _generateId(dependentHabit.id.toString(), now) + 1; // +1 to avoid collision if somehow time cue also exists
    
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: 'A moment for ${dependentHabit.name}',
      body: 'You are someone who shows up. Even ${dependentHabit.twoMinuteVersion} counts.',
      notificationDetails: _notificationDetails(dependentHabit.id.toString(), now),
    );
  }

  NotificationDetails _notificationDetails(String habitId, DateTime date) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'forge_habits_channel',
        'Habit Reminders',
        channelDescription: 'Reminders for your habits',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('done', 'Done'),
          AndroidNotificationAction('twoMinute', '2-min version'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'habit_reminders',
      ),
    );
  }

  Future<void> scheduleWeeklyReview(bool enabled) async {
    final id = _generateWeeklyReviewId();
    await _flutterLocalNotificationsPlugin.cancel(id: id);
    
    if (!enabled) return;

    // Schedule for next Sunday 6 PM
    final now = DateTime.now();
    var nextSunday = now;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    
    var scheduledDate = tz.TZDateTime.local(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);
    
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Weekly Review',
      body: 'Your week in review is ready.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'forge_weekly_review',
          'Weekly Review',
          channelDescription: 'Weekly insights and friction report',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly
    );
  }
}
