import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:forge/models/habit.dart';
import 'package:forge/models/habit_stack.dart';
import 'package:forge/providers/stack_provider.dart';

void main() {
  late Isar isar;
  late StackNotifier stackNotifier;

  Habit createHabit(String name, {CueType cueType = CueType.time, String cueValue = '00:00', String? stackId, int stackOrder = 0}) {
    return Habit()
      ..name = name
      ..cueType = cueType
      ..cueValue = cueValue
      ..twoMinuteVersion = 'two mins'
      ..frequency = (Frequency()..type = FrequencyType.daily)
      ..stackId = stackId
      ..stackOrder = stackOrder
      ..createdAt = DateTime.now();
  }

  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [HabitSchema, HabitStackSchema],
      directory: '',
      name: 'test_db_${DateTime.now().millisecondsSinceEpoch}',
    );
    stackNotifier = StackNotifier(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('DFS Cycle Detection', () {
    test('wouldCreateCycle returns true for self', () async {
      final habitId = '1';
      final result = await stackNotifier.wouldCreateCycle(habitId, habitId);
      expect(result, isTrue);
    });

    test('wouldCreateCycle returns false for unconnected habits', () async {
      await isar.writeTxn(() async {
        await isar.habits.putAll([
          createHabit('H1'),
          createHabit('H2'),
        ]);
      });
      final result = await stackNotifier.wouldCreateCycle('1', '2');
      expect(result, isFalse);
    });

    test('wouldCreateCycle returns true if moving H1 after H2 creates a loop', () async {
      await isar.writeTxn(() async {
        await isar.habits.putAll([
          createHabit('H1'),
          createHabit('H2', cueType: CueType.afterHabit, cueValue: '1'),
          createHabit('H3', cueType: CueType.afterHabit, cueValue: '2'),
        ]);
      });
      
      final result = await stackNotifier.wouldCreateCycle('1', '3');
      expect(result, isTrue);
    });
    
    test('wouldCreateCycle returns false for valid reorders', () async {
      await isar.writeTxn(() async {
        await isar.habits.putAll([
          createHabit('H1'),
          createHabit('H2', cueType: CueType.afterHabit, cueValue: '1'),
          createHabit('H3', cueType: CueType.afterHabit, cueValue: '2'),
        ]);
      });
      
      final result = await stackNotifier.wouldCreateCycle('3', '1');
      expect(result, isFalse);
    });
  });

  group('Stack Topology Operations', () {
    test('moveHabitAfter creates a new stack if target is standalone', () async {
      await isar.writeTxn(() async {
        await isar.habits.putAll([
          createHabit('H1'),
          createHabit('H2'),
        ]);
      });

      await stackNotifier.moveHabitAfter('2', '1');

      final h1 = await isar.habits.get(1);
      final h2 = await isar.habits.get(2);
      final stacks = await isar.habitStacks.where().findAll();

      expect(stacks.length, 1);
      expect(stacks.first.habitIds, ['1', '2']);
      
      expect(h1?.stackId, stacks.first.id.toString());
      expect(h1?.stackOrder, 0);

      expect(h2?.stackId, stacks.first.id.toString());
      expect(h2?.stackOrder, 1);
      expect(h2?.cueType, CueType.afterHabit);
      expect(h2?.cueValue, '1');
    });

    test('moveHabitAfter un-stacks a habit if target is null', () async {
      final stack = HabitStack()..name = 'S1'..habitIds = ['1', '2'];
      await isar.writeTxn(() async {
        await isar.habitStacks.put(stack);
        await isar.habits.putAll([
          createHabit('H1', stackId: stack.id.toString(), stackOrder: 0),
          createHabit('H2', stackId: stack.id.toString(), stackOrder: 1, cueType: CueType.afterHabit, cueValue: '1'),
        ]);
      });

      await stackNotifier.moveHabitAfter('2', null);

      final h2 = await isar.habits.get(2);
      expect(h2?.stackId, isNull);
      expect(h2?.stackOrder, 0);
      expect(h2?.cueType, CueType.time);

      final stacks = await isar.habitStacks.where().findAll();
      expect(stacks.isEmpty, isTrue);

      final h1 = await isar.habits.get(1);
      expect(h1?.stackId, isNull);
    });

    test('archiveHabitWithStackHandling splits a stack', () async {
      final stack = HabitStack()..name = 'S1'..habitIds = ['1', '2', '3'];
      await isar.writeTxn(() async {
        await isar.habitStacks.put(stack);
        await isar.habits.putAll([
          createHabit('H1', stackId: stack.id.toString(), stackOrder: 0),
          createHabit('H2', stackId: stack.id.toString(), stackOrder: 1, cueType: CueType.afterHabit, cueValue: '1'),
          createHabit('H3', stackId: stack.id.toString(), stackOrder: 2, cueType: CueType.afterHabit, cueValue: '2'),
        ]);
      });

      await stackNotifier.archiveHabitWithStackHandling('2', split: true);

      final h2 = await isar.habits.get(2);
      expect(h2?.isArchived, isTrue);
      expect(h2?.stackId, isNull);

      final stacks = await isar.habitStacks.where().findAll();
      expect(stacks.isEmpty, isTrue);

      final h1 = await isar.habits.get(1);
      final h3 = await isar.habits.get(3);
      expect(h1?.stackId, isNull);
      expect(h3?.stackId, isNull);
      expect(h3?.cueType, CueType.time);
    });

    test('archiveHabitWithStackHandling reconnects a stack', () async {
      final stack = HabitStack()..name = 'S1'..habitIds = ['1', '2', '3'];
      await isar.writeTxn(() async {
        await isar.habitStacks.put(stack);
        await isar.habits.putAll([
          createHabit('H1', stackId: stack.id.toString(), stackOrder: 0),
          createHabit('H2', stackId: stack.id.toString(), stackOrder: 1, cueType: CueType.afterHabit, cueValue: '1'),
          createHabit('H3', stackId: stack.id.toString(), stackOrder: 2, cueType: CueType.afterHabit, cueValue: '2'),
        ]);
      });

      await stackNotifier.archiveHabitWithStackHandling('2', split: false);

      final stacks = await isar.habitStacks.where().findAll();
      expect(stacks.length, 1);
      expect(stacks.first.habitIds, ['1', '3']);

      final h3 = await isar.habits.get(3);
      expect(h3?.stackOrder, 1);
      expect(h3?.cueType, CueType.afterHabit);
      expect(h3?.cueValue, '1');
    });
  });
}
