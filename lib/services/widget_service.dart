// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:isar/isar.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/user_settings.dart';
import '../utils/date_time_utils.dart';
import '../utils/habit_utils.dart';

class WidgetService {
  static const String appGroupId = 'group.com.forge.app'; // Optional for iOS, typically used for shared prefs

  static Future<void> updateWidgetData(Isar isar, UserSettings settings) async {
    try {
      final now = DateTime.now();
      final today = DateTimeUtils.resolveAppToday(now, settings.dayStartTime);

      final habits = await isar.habits.filter().isArchivedEqualTo(false).findAll();
      final logs = await isar.habitLogs.filter().dateEqualTo(today).findAll();

      final List<Map<String, dynamic>> widgetData = [];

      for (var habit in habits) {
        if (!HabitUtils.isScheduledOn(habit, today)) continue;

        final log = logs.where((l) => l.habitId == habit.id.toString()).firstOrNull;
        
        widgetData.add({
          'name': habit.name,
          'status': log?.status.name ?? 'pending',
        });
      }

      final jsonString = jsonEncode(widgetData);

      await HomeWidget.saveWidgetData<String>('forge_today_summary', jsonString);
      await HomeWidget.updateWidget(
        name: 'ForgeWidgetProvider',
        androidName: 'ForgeWidgetProvider',
        iOSName: 'ForgeWidget', // Future iOS support
      );
    } catch (e) {
      print('Failed to update widget: $e');
    }
  }
}
