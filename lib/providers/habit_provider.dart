import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/consistency_score.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/identity.dart';
import '../models/user_settings.dart';
import '../utils/date_time_utils.dart';
import '../utils/habit_utils.dart';
import '../services/notification_service.dart';
import 'user_settings_provider.dart';

final habitListProvider = StreamProvider<List<Habit>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.habits.filter().isArchivedEqualTo(false).watch(fireImmediately: true);
});

final consistencyScoreProvider = StreamProvider.family<ConsistencyScore?, String>((ref, habitId) {
  final isar = ref.watch(isarProvider);
  return isar.consistencyScores.filter().habitIdEqualTo(habitId).watch(fireImmediately: true).map((scores) => scores.isEmpty ? null : scores.first);
});

final habitLogsProvider = StreamProvider.family<List<HabitLog>, String>((ref, habitId) {
  final isar = ref.watch(isarProvider);
  return isar.habitLogs.filter().habitIdEqualTo(habitId).sortByDateDesc().watch(fireImmediately: true);
});

class HabitNotifier {
  final Isar isar;
  final UserSettings userSettings;

  HabitNotifier(this.isar, this.userSettings);

  Future<Habit> saveHabit(Habit habit) async {
    await isar.writeTxn(() async {
      final isNew = habit.id == Isar.autoIncrement;
      if (isNew) {
        habit.createdAt = DateTime.now();
      }
      await isar.habits.put(habit);

      if (habit.identityStatementId != null) {
        final identity = await isar.identitys.get(int.parse(habit.identityStatementId!));
        if (identity != null && !identity.linkedHabitIds.contains(habit.id.toString())) {
          identity.linkedHabitIds = [...identity.linkedHabitIds, habit.id.toString()];
          await isar.identitys.put(identity);
        }
      }

      if (isNew) {
        final score = ConsistencyScore()
          ..habitId = habit.id.toString()
          ..score = 0.0
          ..lastUpdated = DateTime.now();
        await isar.consistencyScores.put(score);
      }
    });
    
    // Notifications scheduling
    if (!habit.isArchived) {
      await NotificationService().scheduleHabitReminders(habit);
    }
    
    return habit;
  }

  Future<void> archiveHabit(String habitId) async {
    final id = int.tryParse(habitId);
    if (id == null) return;

    await isar.writeTxn(() async {
      final habit = await isar.habits.get(id);
      if (habit != null) {
        habit.isArchived = true;
        await isar.habits.put(habit);
      }
    });
    
    await NotificationService().cancelAllRemindersForHabit(habitId);
  }

  Future<void> logHabit(String habitId, DateTime logDate, LogStatus status) async {
    final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);
    
    // Normalize logDate
    final normalizedDate = DateTime(logDate.year, logDate.month, logDate.day);
    final isBackfilled = normalizedDate.isBefore(today);

    await isar.writeTxn(() async {
      // Upsert log
      var log = await isar.habitLogs
          .filter()
          .habitIdEqualTo(habitId)
          .dateEqualTo(normalizedDate)
          .findFirst();

      if (log == null) {
        log = HabitLog()
          ..habitId = habitId
          ..date = normalizedDate
          ..loggedAt = DateTime.now()
          ..isBackfilled = isBackfilled;
      } else {
        log.loggedAt = DateTime.now();
        log.isBackfilled = isBackfilled;
      }
      log.status = status;
      await isar.habitLogs.put(log);

      // Recompute score
      final habit = await isar.habits.get(int.parse(habitId));
      if (habit != null) {
        final allLogs = await isar.habitLogs.filter().habitIdEqualTo(habitId).findAll();
        final newScoreVal = HabitUtils.computeConsistencyScore(habit, allLogs, today);

        var score = await isar.consistencyScores.filter().habitIdEqualTo(habitId).findFirst();
        if (score == null) {
          score = ConsistencyScore()
            ..habitId = habitId
            ..score = newScoreVal
            ..lastUpdated = DateTime.now();
        } else {
          score.score = newScoreVal;
          score.lastUpdated = DateTime.now();
        }
        await isar.consistencyScores.put(score);
      }
    });

    if (status == LogStatus.done || status == LogStatus.doneViaTwoMinute) {
      await NotificationService().cancelHabitRemindersForToday(habitId, normalizedDate);

      // Trigger dependent habits if any
      final dependentHabits = await isar.habits.filter()
          .cueTypeEqualTo(CueType.afterHabit)
          .cueValueEqualTo(habitId)
          .isArchivedEqualTo(false)
          .findAll();
      
      for (final dependent in dependentHabits) {
        // Only trigger if not already logged today
        final existingLog = await isar.habitLogs.filter()
            .habitIdEqualTo(dependent.id.toString())
            .dateEqualTo(normalizedDate)
            .findFirst();
        
        final alreadyDone = existingLog?.status == LogStatus.done || existingLog?.status == LogStatus.doneViaTwoMinute;
        if (!alreadyDone) {
          await NotificationService().triggerAfterHabitNotification(dependent);
        }
      }
    }
  }

  Future<void> updateEnvironmentReady(String habitId, DateTime logDate, bool isReady) async {
    final normalizedDate = DateTime(logDate.year, logDate.month, logDate.day);
    await isar.writeTxn(() async {
      final log = await isar.habitLogs
          .filter()
          .habitIdEqualTo(habitId)
          .dateEqualTo(normalizedDate)
          .findFirst();

      if (log != null) {
        log.environmentReady = isReady;
        await isar.habitLogs.put(log);
      }
    });
  }
}

final habitNotifierProvider = Provider<HabitNotifier>((ref) {
  return HabitNotifier(ref.watch(isarProvider), ref.watch(userSettingsProvider));
});
