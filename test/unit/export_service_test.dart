import 'package:flutter_test/flutter_test.dart';
import 'package:forge/services/export_service.dart';
import 'package:forge/models/habit.dart';
import 'package:forge/models/habit_log.dart';

void main() {
  group('ExportService Tests', () {
    test('generateCsvString produces correctly formatted rows', () {
      final habits = [
        Habit()
          ..id = 1
          ..name = 'Morning Run',
        Habit()
          ..id = 2
          ..name = 'Read Book, 10 Pages',
      ];

      final logs = [
        HabitLog()
          ..id = 1
          ..habitId = '1'
          ..date = DateTime(2026, 1, 1)
          ..status = LogStatus.done
          ..isBackfilled = false,
        HabitLog()
          ..id = 2
          ..habitId = '2'
          ..date = DateTime(2026, 1, 2)
          ..status = LogStatus.missed
          ..isBackfilled = true,
      ];

      final csvString = ExportService.generateCsvString(logs, habits);
      final lines = csvString.trim().split('\n');

      expect(lines.length, 3);
      expect(lines[0], 'Habit Name,Date,Status,Backfilled');
      expect(lines[1], '"Morning Run",2026-01-01,done,No');
      // Ensure quotes are preserved and correctly escaped if there were any, though basic wrapping happens
      expect(lines[2], '"Read Book, 10 Pages",2026-01-02,missed,Yes');
    });

    test('generateCsvString handles empty states gracefully', () {
      final csvString = ExportService.generateCsvString([], []);
      final lines = csvString.trim().split('\n');

      expect(lines.length, 1);
      expect(lines[0], 'Habit Name,Date,Status,Backfilled');
    });
  });
}
