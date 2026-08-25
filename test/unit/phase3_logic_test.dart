import 'package:flutter_test/flutter_test.dart';
import 'package:forge/models/habit.dart';
import 'package:forge/models/habit_log.dart';
import 'package:forge/utils/habit_utils.dart';

void main() {
  group('Phase 3 Unit Tests', () {
    test('Historical score replay final value matches final computeConsistencyScore', () {
      final habit = Habit()
        ..name = 'Test Habit'
        ..createdAt = DateTime(2023, 1, 1)
        ..frequency = (Frequency()..type = FrequencyType.daily);

      final logs = [
        HabitLog()..date = DateTime(2023, 1, 1)..status = LogStatus.done,
        HabitLog()..date = DateTime(2023, 1, 2)..status = LogStatus.missed,
        HabitLog()..date = DateTime(2023, 1, 3)..status = LogStatus.doneViaTwoMinute,
        HabitLog()..date = DateTime(2023, 1, 4)..status = LogStatus.excused,
      ];

      final todayAppDate = DateTime(2023, 1, 5);

      final history = HabitUtils.computeConsistencyScoreHistory(habit, logs, todayAppDate);
      final finalScore = HabitUtils.computeConsistencyScore(habit, logs, todayAppDate);

      expect(history.isNotEmpty, true);
      expect(history.values.last, finalScore);
    });

    test('Projection formula calculations', () {
      // If trailingCompletionRate = 1.0 (100% done)
      // score = 1 * (score + (100 - score) * 0.2)
      // If starting score is 50: 
      // Day 1: 50 + 50*0.2 = 60
      // Day 2: 60 + 40*0.2 = 68
      
      double score = 50.0;
      final rate = 1.0;
      
      score = rate * (score + (100.0 - score) * 0.2) + (1.0 - rate) * (score * 0.9);
      expect(score, 60.0);
      
      score = rate * (score + (100.0 - score) * 0.2) + (1.0 - rate) * (score * 0.9);
      expect(score, 68.0);
      
      // If trailingCompletionRate = 0.0 (0% done)
      // score = 0.9 * score
      double score2 = 50.0;
      final rate2 = 0.0;
      
      score2 = rate2 * (score2 + (100.0 - score2) * 0.2) + (1.0 - rate2) * (score2 * 0.9);
      expect(score2, 45.0);
    });
  });
}
