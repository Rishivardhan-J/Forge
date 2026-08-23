import '../models/habit.dart';
import '../models/habit_log.dart';

class HabitUtils {
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

  /// Computes the consistency score chronologically from createdAt to today.
  static double computeConsistencyScore(
    Habit habit, 
    List<HabitLog> logs, 
    DateTime todayAppDate,
  ) {
    double score = 0.0;
    
    // Normalize createdAt to midnight for iteration
    var currentDay = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    
    // Create a fast lookup map for logs by date
    final logMap = <DateTime, HabitLog>{};
    for (var log in logs) {
      final normalizedDate = DateTime(log.date.year, log.date.month, log.date.day);
      logMap[normalizedDate] = log;
    }

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
        break; // we can break because it's the last day anyway
      }

      // Apply formula
      if (resolvedStatus == LogStatus.done || resolvedStatus == LogStatus.doneViaTwoMinute) {
        score = score + (100.0 - score) * 0.2;
      } else if (resolvedStatus == LogStatus.missed) {
        score = score * 0.9;
      }
      // notScheduled and excused leave score unchanged

      currentDay = currentDay.add(const Duration(days: 1));
    }

    return score;
  }
}
