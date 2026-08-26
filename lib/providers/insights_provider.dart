import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/date_time_utils.dart';
import '../utils/habit_utils.dart';
import 'user_settings_provider.dart';

class ChartPoint {
  final DateTime date;
  final double score;
  ChartPoint(this.date, this.score);
}

class ChartData {
  final List<ChartPoint> historical;
  final List<ChartPoint> projected;
  final bool notEnoughHistory;

  ChartData(this.historical, this.projected, this.notEnoughHistory);
}

final insightsChartProvider = FutureProvider.family<ChartData, String?>((ref, selectedHabitId) async {
  final isar = ref.watch(isarProvider);
  final userSettings = ref.watch(userSettingsProvider);
  final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);

  List<Habit> habitsToProcess = [];
  
  if (selectedHabitId != null) {
    final habit = await isar.habits.get(int.parse(selectedHabitId));
    if (habit != null && !habit.isArchived) habitsToProcess.add(habit);
  } else {
    habitsToProcess = await isar.habits.filter().isArchivedEqualTo(false).findAll();
  }

  if (habitsToProcess.isEmpty) {
    return ChartData([], [], true);
  }

  final chartStart = today.subtract(const Duration(days: 30));
  
  // 1. Compute historical scores per habit
  final Map<String, Map<DateTime, double>> allHistories = {};
  for (final habit in habitsToProcess) {
    final logs = await isar.habitLogs.filter().habitIdEqualTo(habit.id.toString()).findAll();
    allHistories[habit.id.toString()] = HabitUtils.computeConsistencyScoreHistory(habit, logs, today);
  }

  // 2. Aggregate history (mean)
  final historicalPoints = <ChartPoint>[];
  var current = chartStart;
  while (current.isBefore(today) || current.isAtSameMomentAs(today)) {
    double sum = 0.0;
    int count = 0;
    
    for (final habit in habitsToProcess) {
      final hId = habit.id.toString();
      final history = allHistories[hId];
      if (history != null && history.containsKey(current)) {
        sum += history[current]!;
        count++;
      } else if (history != null && history.isNotEmpty) {
        // If the date is before habit creation, it's not in the map.
        // If it's in the map but earlier dates are missing, it shouldn't happen based on our logic, 
        // but if it's missing just skip it.
      }
    }
    
    if (count > 0) {
      historicalPoints.add(ChartPoint(current, sum / count));
    }
    current = current.add(const Duration(days: 1));
  }

  if (historicalPoints.isEmpty) {
    return ChartData([], [], true);
  }
  
  final latestScore = historicalPoints.last.score;

  // 3. Compute Trailing Completion Rate (14 days)
  final projectionStart = today.subtract(const Duration(days: 13)); // today-13 to today (14 days inclusive)
  int doneCount = 0;
  int scheduledCount = 0;
  
  for (final habit in habitsToProcess) {
    final logs = await isar.habitLogs.filter().habitIdEqualTo(habit.id.toString()).dateBetween(projectionStart, today).findAll();
    final logMap = {for (var log in logs) log.date: log};
    
    var d = projectionStart;
    while (d.isBefore(today) || d.isAtSameMomentAs(today)) {
      if (d.isBefore(habit.createdAt)) {
        // Skip days before habit existed
        d = d.add(const Duration(days: 1));
        continue;
      }
      
      final isScheduled = HabitUtils.isScheduledOn(habit, d);
      final log = logMap[d];
      
      if (log != null && log.status == LogStatus.excused) {
        // Excused is not counted in denominator
      } else if (!isScheduled && log == null) {
        // not scheduled and not logged -> skip
      } else if (!isScheduled && log != null && log.status == LogStatus.notScheduled) {
        // skipped
      } else {
        scheduledCount++;
        if (log != null && (log.status == LogStatus.done || log.status == LogStatus.doneViaTwoMinute)) {
          doneCount++;
        }
      }
      
      d = d.add(const Duration(days: 1));
    }
  }

  if (scheduledCount == 0) {
    return ChartData(historicalPoints, [], true);
  }

  final trailingCompletionRate = doneCount / scheduledCount;
  
  // 4. Project 14 days forward
  final projectedPoints = <ChartPoint>[];
  double projScore = latestScore;
  current = today.add(const Duration(days: 1));
  
  for (int i = 0; i < 14; i++) {
    projScore = trailingCompletionRate * (projScore + (100.0 - projScore) * 0.2) +
                (1.0 - trailingCompletionRate) * (projScore * 0.9);
    projectedPoints.add(ChartPoint(current, projScore));
    current = current.add(const Duration(days: 1));
  }

  return ChartData(historicalPoints, projectedPoints, false);
});

class FrictionReportEntry {
  final String habitName;
  final int missedCount;
  final int unreadyCount;

  FrictionReportEntry({
    required this.habitName,
    required this.missedCount,
    required this.unreadyCount,
  });
}

final frictionReportProvider = FutureProvider<List<FrictionReportEntry>>((ref) async {
  final isar = ref.watch(isarProvider);
  final userSettings = ref.watch(userSettingsProvider);
  final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);
  
  // Rolling 7 days, from today - 7 to today - 1
  final windowEnd = today.subtract(const Duration(days: 1));
  final windowStart = today.subtract(const Duration(days: 7));

  final habits = await isar.habits.filter().isArchivedEqualTo(false).environmentTagIdIsNotNull().findAll();
  
  final report = <FrictionReportEntry>[];
  
  for (final habit in habits) {
    final missedLogs = await isar.habitLogs.filter()
      .habitIdEqualTo(habit.id.toString())
      .dateBetween(windowStart, windowEnd)
      .statusEqualTo(LogStatus.missed)
      .findAll();
      
    if (missedLogs.isEmpty) continue;
    
    final unreadyCount = missedLogs.where((log) => log.environmentReady == false).length;
    if (unreadyCount == 0) continue;
    
    report.add(FrictionReportEntry(
      habitName: habit.name,
      missedCount: missedLogs.length,
      unreadyCount: unreadyCount,
    ));
  }
  
  report.sort((a, b) => b.unreadyCount.compareTo(a.unreadyCount));
  return report.take(5).toList();
});
