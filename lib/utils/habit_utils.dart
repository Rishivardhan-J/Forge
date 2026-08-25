import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class HabitUtils {
  static void showEnvironmentReadyPrompt(BuildContext context, WidgetRef ref, Habit habit, DateTime logDate) {
    if (habit.environmentTagId == null) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Expanded(child: Text('Was your environment ready?')),
            TextButton(
              onPressed: () {
                ref.read(habitNotifierProvider).updateEnvironmentReady(habit.id.toString(), logDate, true);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('Yes', style: TextStyle(color: AppTheme.accentGrowthFill)),
            ),
            TextButton(
              onPressed: () {
                ref.read(habitNotifierProvider).updateEnvironmentReady(habit.id.toString(), logDate, false);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('No', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: AppTheme.bgSurfaceRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  /// Determines if a habit is scheduled to be performed on a specific [appDate].
  static bool isScheduledOn(Habit habit, DateTime appDate) {
    if (habit.pausedUntil != null && (appDate.isBefore(habit.pausedUntil!) || appDate.isAtSameMomentAs(habit.pausedUntil!))) {
      return false;
    }

    switch (habit.frequency.type) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.timesPerWeek:
        return true; // Every day is eligible
      case FrequencyType.specificWeekdays:
        // Dart DateTime.weekday is 1=Mon..7=Sun. Spec requires 0=Mon..6=Sun.
        final specWeekday = appDate.weekday - 1;
        return habit.frequency.weekdays?.contains(specWeekday) ?? false;
    }
  }

  /// Computes the consistency score history chronologically from createdAt to today.
  static Map<DateTime, double> computeConsistencyScoreHistory(
    Habit habit, 
    List<HabitLog> logs, 
    DateTime todayAppDate,
  ) {
    double score = 0.0;
    var currentDay = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    
    final logMap = <DateTime, HabitLog>{};
    for (var log in logs) {
      final normalizedDate = DateTime(log.date.year, log.date.month, log.date.day);
      logMap[normalizedDate] = log;
    }

    final history = <DateTime, double>{};

    while (currentDay.isBefore(todayAppDate) || currentDay.isAtSameMomentAs(todayAppDate)) {
      LogStatus? resolvedStatus;
      
      if (logMap.containsKey(currentDay)) {
        resolvedStatus = logMap[currentDay]!.status;
      } else if (!isScheduledOn(habit, currentDay)) {
        resolvedStatus = LogStatus.notScheduled;
      } else if (currentDay.isBefore(todayAppDate)) {
        resolvedStatus = LogStatus.missed;
      } else {
        // currentDay == todayAppDate and no log yet -> skip
        break; 
      }

      // Apply formula
      if (resolvedStatus == LogStatus.done || resolvedStatus == LogStatus.doneViaTwoMinute) {
        score = score + (100.0 - score) * 0.2;
      } else if (resolvedStatus == LogStatus.missed) {
        score = score * 0.9;
      }

      history[currentDay] = score;
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return history;
  }

  /// Computes the consistency score chronologically from createdAt to today.
  static double computeConsistencyScore(
    Habit habit, 
    List<HabitLog> logs, 
    DateTime todayAppDate,
  ) {
    final history = computeConsistencyScoreHistory(habit, logs, todayAppDate);
    if (history.isEmpty) return 0.0;
    return history.values.last;
  }
}
