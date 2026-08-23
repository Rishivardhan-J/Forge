import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/habit.dart';
import '../models/habit_stack.dart';
import '../providers/habit_provider.dart';

final stackListProvider = StreamProvider<List<HabitStack>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.habitStacks.where().watch(fireImmediately: true);
});

class StackNotifier {
  final Isar isar;

  StackNotifier(this.isar);

  /// Run a DFS to check if placing [habitId] after [targetHabitId] would create a cycle
  /// by following `afterHabit` cues forward from [habitId].
  Future<bool> wouldCreateCycle(String habitId, String targetHabitId) async {
    if (habitId == targetHabitId) return true;

    final visited = <String>{};
    final queue = <String>[habitId]; // we start at habitId, and look for what comes after it

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current == targetHabitId) return true;
      
      if (!visited.contains(current)) {
        visited.add(current);
        
        // Find all habits that come AFTER 'current'
        final nextHabits = await isar.habits
            .filter()
            .cueTypeEqualTo(CueType.afterHabit)
            .cueValueEqualTo(current)
            .findAll();
            
        for (final h in nextHabits) {
          queue.add(h.id.toString());
        }
      }
    }

    return false;
  }

  /// Places [habitId] after [targetHabitId]. 
  /// If [targetHabitId] is null, un-stacks [habitId].
  Future<void> moveHabitAfter(String habitId, String? targetHabitId) async {
    final hId = int.tryParse(habitId);
    if (hId == null) return;

    await isar.writeTxn(() async {
      final habit = await isar.habits.get(hId);
      if (habit == null) return;

      // Unstacking
      if (targetHabitId == null) {
        await _removeFromStack(habit);
        return;
      }

      // Stacking
      final targetId = int.tryParse(targetHabitId);
      if (targetId == null) return;
      final targetHabit = await isar.habits.get(targetId);
      if (targetHabit == null) return;

      // If target is in a stack, insert after it. If not, create a new stack.
      if (targetHabit.stackId != null) {
        final stack = await isar.habitStacks.get(int.parse(targetHabit.stackId!));
        if (stack != null) {
          await _removeFromStack(habit); // remove from old stack if any
          
          final targetIndex = stack.habitIds.indexOf(targetHabitId);
          if (targetIndex != -1) {
            stack.habitIds = List.from(stack.habitIds)..insert(targetIndex + 1, habitId);
          } else {
            stack.habitIds = List.from(stack.habitIds)..add(habitId);
          }
          
          await _updateStackAndHabits(stack);
        }
      } else {
        // Create new stack with targetHabit then habit
        await _removeFromStack(habit);
        
        final newStack = HabitStack()
          ..name = 'Stack'
          ..habitIds = [targetHabitId, habitId];
          
        await isar.habitStacks.put(newStack);
        
        targetHabit.stackId = newStack.id.toString();
        targetHabit.stackOrder = 0;
        await isar.habits.put(targetHabit);
        
        habit.stackId = newStack.id.toString();
        habit.stackOrder = 1;
        habit.cueType = CueType.afterHabit;
        habit.cueValue = targetHabitId;
        await isar.habits.put(habit);
      }
    });
  }

  /// Removes habit from its current stack, updating the stack's habitIds 
  /// and rewiring the next habit's cue if needed.
  Future<void> _removeFromStack(Habit habit) async {
    if (habit.stackId == null) return;
    
    final stack = await isar.habitStacks.get(int.parse(habit.stackId!));
    if (stack == null) {
      habit.stackId = null;
      habit.stackOrder = 0;
      if (habit.cueType == CueType.afterHabit) {
        habit.cueType = CueType.time; // Reset to safe default
        habit.cueValue = "00:00";
      }
      await isar.habits.put(habit);
      return;
    }

    final index = stack.habitIds.indexOf(habit.id.toString());
    if (index != -1) {
      stack.habitIds = List.from(stack.habitIds)..removeAt(index);
      
      if (stack.habitIds.length <= 1) {
        // Destroy the stack
        for (final remainingIdStr in stack.habitIds) {
          final h = await isar.habits.get(int.parse(remainingIdStr));
          if (h != null) {
            h.stackId = null;
            h.stackOrder = 0;
            // keep its cue if it was the first, or reset if it was afterHabit
            if (h.cueType == CueType.afterHabit && h.cueValue == habit.id.toString()) {
              h.cueType = CueType.time;
              h.cueValue = "00:00";
            }
            await isar.habits.put(h);
          }
        }
        await isar.habitStacks.delete(stack.id);
      } else {
        // Update the stack
        await _updateStackAndHabits(stack);
      }
    }

    habit.stackId = null;
    habit.stackOrder = 0;
    if (habit.cueType == CueType.afterHabit) {
      habit.cueType = CueType.time;
      habit.cueValue = "00:00";
    }
    await isar.habits.put(habit);
  }

  Future<void> _updateStackAndHabits(HabitStack stack) async {
    await isar.habitStacks.put(stack);
    
    for (int i = 0; i < stack.habitIds.length; i++) {
      final hId = int.parse(stack.habitIds[i]);
      final h = await isar.habits.get(hId);
      if (h != null) {
        h.stackId = stack.id.toString();
        h.stackOrder = i;
        if (i > 0) {
          h.cueType = CueType.afterHabit;
          h.cueValue = stack.habitIds[i - 1];
        }
        await isar.habits.put(h);
      }
    }
  }

  /// Archive a habit with mid-stack handling (Reconnect vs Split)
  Future<void> archiveHabitWithStackHandling(String habitId, {bool split = false}) async {
    final hId = int.tryParse(habitId);
    if (hId == null) return;

    await isar.writeTxn(() async {
      final habit = await isar.habits.get(hId);
      if (habit == null) return;

      if (habit.stackId != null) {
        final stack = await isar.habitStacks.get(int.parse(habit.stackId!));
        if (stack != null) {
          final index = stack.habitIds.indexOf(habitId);
          if (index > 0 && index < stack.habitIds.length - 1 && split) {
            // Split the stack!
            final firstPart = stack.habitIds.sublist(0, index);
            final secondPart = stack.habitIds.sublist(index + 1);

            stack.habitIds = firstPart;
            await _updateStackAndHabits(stack); // This handles size <= 1 destruction automatically?
            // Actually _updateStackAndHabits doesn't destroy. Let's do it manually if needed.
            
            final newStack = HabitStack()
              ..name = '${stack.name} (2)'
              ..habitIds = secondPart;
            
            await isar.habitStacks.put(newStack);
            
            // Fix cues for second part's new root
            final newRoot = await isar.habits.get(int.parse(secondPart.first));
            if (newRoot != null) {
              newRoot.cueType = CueType.time;
              newRoot.cueValue = "00:00";
              await isar.habits.put(newRoot);
            }
            await _updateStackAndHabits(newStack);

            // Check if sizes <= 1
            if (firstPart.length <= 1) {
               await _destroyStack(stack.id, firstPart);
            }
            if (secondPart.length <= 1) {
               await _destroyStack(newStack.id, secondPart);
            }
          } else {
            // Reconnect or edge case (first/last)
            stack.habitIds = List.from(stack.habitIds)..removeAt(index);
            if (stack.habitIds.length <= 1) {
               await _destroyStack(stack.id, stack.habitIds);
            } else {
               await _updateStackAndHabits(stack);
            }
          }
        }
      }

      habit.isArchived = true;
      habit.stackId = null;
      habit.stackOrder = 0;
      await isar.habits.put(habit);
    });
  }

  Future<void> _destroyStack(int stackId, List<String> habitIds) async {
    for (final idStr in habitIds) {
      final h = await isar.habits.get(int.parse(idStr));
      if (h != null) {
        h.stackId = null;
        h.stackOrder = 0;
        await isar.habits.put(h);
      }
    }
    await isar.habitStacks.delete(stackId);
  }
}

final stackNotifierProvider = Provider<StackNotifier>((ref) {
  return StackNotifier(ref.watch(isarProvider));
});
