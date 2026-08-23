import 'package:flutter_test/flutter_test.dart';
import 'package:forge/models/habit.dart';
import 'package:forge/models/habit_log.dart';
import 'package:forge/utils/date_time_utils.dart';
import 'package:forge/utils/habit_utils.dart';

void main() {
  group('DateTimeUtils', () {
    test('dayStartTime 00:00 (default)', () {
      final now = DateTime(2023, 10, 5, 1, 0); // 1 AM
      final appToday = DateTimeUtils.resolveAppToday(now, '00:00');
      expect(appToday, DateTime(2023, 10, 5));
    });

    test('dayStartTime 04:00 with log at 1 AM (previous day)', () {
      final now = DateTime(2023, 10, 5, 1, 0); // 1 AM
      final appToday = DateTimeUtils.resolveAppToday(now, '04:00');
      expect(appToday, DateTime(2023, 10, 4));
    });

    test('dayStartTime 04:00 with log at 5 AM (current day)', () {
      final now = DateTime(2023, 10, 5, 5, 0); // 5 AM
      final appToday = DateTimeUtils.resolveAppToday(now, '04:00');
      expect(appToday, DateTime(2023, 10, 5));
    });
  });

  group('HabitUtils isScheduledOn', () {
    test('specificWeekdays returns false for unscheduled day', () {
      final habit = Habit()
        ..frequency = (Frequency()
          ..type = FrequencyType.specificWeekdays
          ..weekdays = [0, 2, 4]); // Mon, Wed, Fri
      
      // 2023-10-03 is a Tuesday
      final tuesday = DateTime(2023, 10, 3);
      expect(HabitUtils.isScheduledOn(habit, tuesday), isFalse);

      // 2023-10-04 is a Wednesday
      final wednesday = DateTime(2023, 10, 4);
      expect(HabitUtils.isScheduledOn(habit, wednesday), isTrue);
    });

    test('pausedUntil overrides frequency', () {
      final habit = Habit()
        ..frequency = (Frequency()..type = FrequencyType.daily)
        ..pausedUntil = DateTime(2023, 10, 10);
      
      final appDate = DateTime(2023, 10, 9);
      expect(HabitUtils.isScheduledOn(habit, appDate), isFalse);
    });
  });

  group('HabitUtils computeConsistencyScore', () {
    test('Fresh habit logging done 5 days in a row', () {
      final habit = Habit()
        ..createdAt = DateTime(2023, 10, 1)
        ..frequency = (Frequency()..type = FrequencyType.daily);

      final logs = <HabitLog>[];
      double expectedScore = 0.0;

      for (int i = 0; i < 5; i++) {
        final d = DateTime(2023, 10, 1 + i);
        logs.add(HabitLog()
          ..date = d
          ..status = LogStatus.done);
        
        expectedScore = expectedScore + (100.0 - expectedScore) * 0.2;
        
        final score = HabitUtils.computeConsistencyScore(habit, logs, d);
        expect(score, closeTo(expectedScore, 0.001));
      }
    });

    test('Habit with 2 misses in a row', () {
      final habit = Habit()
        ..createdAt = DateTime(2023, 10, 1)
        ..frequency = (Frequency()..type = FrequencyType.daily);

      final logs = [
        HabitLog()..date = DateTime(2023, 10, 1)..status = LogStatus.done,
        HabitLog()..date = DateTime(2023, 10, 2)..status = LogStatus.missed,
        HabitLog()..date = DateTime(2023, 10, 3)..status = LogStatus.missed,
      ];

      double expectedScore = 0.0;
      expectedScore += (100.0 - expectedScore) * 0.2; // Day 1
      expectedScore *= 0.9; // Day 2
      expectedScore *= 0.9; // Day 3

      final score = HabitUtils.computeConsistencyScore(habit, logs, DateTime(2023, 10, 3));
      expect(score, closeTo(expectedScore, 0.001));
    });

    test('Habit with notScheduled days interspersed', () {
      final habit = Habit()
        ..createdAt = DateTime(2023, 10, 1) // Sunday
        ..frequency = (Frequency()
          ..type = FrequencyType.specificWeekdays
          ..weekdays = [0, 2, 4]); // Mon, Wed, Fri (Dart weekday 1=Mon)

      // Sunday 1st -> notScheduled
      // Monday 2nd -> done
      // Tuesday 3rd -> notScheduled
      final logs = [
        HabitLog()..date = DateTime(2023, 10, 2)..status = LogStatus.done, // Monday
      ];

      double expectedScore = 0.0;
      expectedScore += (100.0 - expectedScore) * 0.2; // Only Monday counts

      final score = HabitUtils.computeConsistencyScore(habit, logs, DateTime(2023, 10, 3));
      expect(score, closeTo(expectedScore, 0.001));
    });

    test('Habit with excused days interspersed', () {
      final habit = Habit()
        ..createdAt = DateTime(2023, 10, 1)
        ..frequency = (Frequency()..type = FrequencyType.daily);

      final logs = [
        HabitLog()..date = DateTime(2023, 10, 1)..status = LogStatus.done,
        HabitLog()..date = DateTime(2023, 10, 2)..status = LogStatus.excused,
      ];

      double expectedScore = 0.0;
      expectedScore += (100.0 - expectedScore) * 0.2; // Day 1 counts, Day 2 excused

      final score = HabitUtils.computeConsistencyScore(habit, logs, DateTime(2023, 10, 2));
      expect(score, closeTo(expectedScore, 0.001));
    });

    test('Backfilled log written for 3 days ago', () {
      final habit = Habit()
        ..createdAt = DateTime(2023, 10, 1)
        ..frequency = (Frequency()..type = FrequencyType.daily);

      // Suppose today is 4th. We missed 2nd and 3rd implicitly, but then we backfill 2nd as done.
      final logs = [
        HabitLog()..date = DateTime(2023, 10, 1)..status = LogStatus.done,
        HabitLog()..date = DateTime(2023, 10, 2)..status = LogStatus.done, // Backfilled
      ];

      // Day 1: Done
      // Day 2: Done (backfilled)
      // Day 3: Missed (implicit since date < today)
      // Day 4: Today (no log yet, skipped)

      double expectedScore = 0.0;
      expectedScore += (100.0 - expectedScore) * 0.2; // Day 1
      expectedScore += (100.0 - expectedScore) * 0.2; // Day 2
      expectedScore *= 0.9; // Day 3 missed

      final score = HabitUtils.computeConsistencyScore(habit, logs, DateTime(2023, 10, 4));
      expect(score, closeTo(expectedScore, 0.001));
    });
  });
}
