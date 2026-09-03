import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/identity.dart';
import '../models/consistency_score.dart';
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

class InsightsOverview {
  final int completedToday;
  final int scheduledToday;
  final double averageConsistency;
  final String? strongestIdentityStatement;
  final int strongestIdentityVotes;
  final String? mostConsistentHabitName;
  final double mostConsistentHabitScore;
  final String weekOverWeekSentence;
  final bool hasHistory;

  InsightsOverview({
    required this.completedToday,
    required this.scheduledToday,
    required this.averageConsistency,
    this.strongestIdentityStatement,
    required this.strongestIdentityVotes,
    this.mostConsistentHabitName,
    required this.mostConsistentHabitScore,
    required this.weekOverWeekSentence,
    required this.hasHistory,
  });
}

final insightsOverviewProvider = FutureProvider<InsightsOverview>((ref) async {
  final isar = ref.watch(isarProvider);
  final userSettings = ref.watch(userSettingsProvider);
  final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);

  // 1. Today's snapshot
  final unarchivedHabits = await isar.habits.filter().isArchivedEqualTo(false).findAll();
  
  int completedToday = 0;
  int scheduledToday = 0;

  for (final habit in unarchivedHabits) {
    if (HabitUtils.isScheduledOn(habit, today)) {
      scheduledToday++;
      final log = await isar.habitLogs.filter()
          .habitIdEqualTo(habit.id.toString())
          .dateEqualTo(today)
          .findFirst();
      if (log != null && (log.status == LogStatus.done || log.status == LogStatus.doneViaTwoMinute)) {
        completedToday++;
      }
    }
  }

  // 2. Aggregate consistency
  double averageConsistency = 0.0;
  final chartData = await ref.watch(insightsChartProvider(null).future);
  if (chartData.historical.isNotEmpty) {
    averageConsistency = chartData.historical.last.score;
  }

  // 3. Strongest identity
  final identities = await isar.identitys.where().findAll();
  String? strongestStatement;
  int highestVotes = 0;

  for (final identity in identities) {
    final nonArchivedLinked = identity.linkedHabitIds.where((id) => unarchivedHabits.any((h) => h.id.toString() == id)).toList();
    if (nonArchivedLinked.isNotEmpty) {
      final count = await isar.habitLogs.filter()
          .anyOf(nonArchivedLinked, (q, String habitId) => q.habitIdEqualTo(habitId))
          .and()
          .group((q) => q.statusEqualTo(LogStatus.done).or().statusEqualTo(LogStatus.doneViaTwoMinute))
          .count();
      if (count >= highestVotes) {
        highestVotes = count;
        strongestStatement = identity.statement;
      }
    }
  }

  // 4. Most consistent habit
  String? bestHabitName;
  double bestHabitScore = 0.0;

  final scores = await isar.consistencyScores.where().sortByScoreDesc().findAll();
  for (final score in scores) {
    final habit = unarchivedHabits.where((h) => h.id.toString() == score.habitId).firstOrNull;
    if (habit != null) {
      bestHabitName = habit.name;
      bestHabitScore = score.score;
      break;
    }
  }

  // 5. Week-over-week sentence
  String weekSentence = "Not enough history yet.";
  if (chartData.historical.length >= 7) {
    final todayScore = averageConsistency;
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    // Try to find the point exactly 7 days ago, or the closest before it
    final lastWeekPoint = chartData.historical.reversed.firstWhere(
      (p) => p.date.isBefore(sevenDaysAgo) || p.date.isAtSameMomentAs(sevenDaysAgo),
      orElse: () => chartData.historical.first,
    );
    final diff = todayScore - lastWeekPoint.score;
    if (diff.abs() < 1.0) {
      weekSentence = "Holding steady this week.";
    } else if (diff > 0) {
      weekSentence = "Up ${diff.toStringAsFixed(1)} points from last week.";
    } else {
      weekSentence = "Down ${diff.abs().toStringAsFixed(1)} points from last week.";
    }
  }

  return InsightsOverview(
    completedToday: completedToday,
    scheduledToday: scheduledToday,
    averageConsistency: averageConsistency,
    strongestIdentityStatement: strongestStatement,
    strongestIdentityVotes: highestVotes,
    mostConsistentHabitName: bestHabitName,
    mostConsistentHabitScore: bestHabitScore,
    weekOverWeekSentence: weekSentence,
    hasHistory: chartData.historical.isNotEmpty,
  );
});
