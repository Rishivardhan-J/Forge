import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stack_provider.dart';
import '../../theme/app_theme.dart';

class ChainBuilderSheet extends ConsumerStatefulWidget {
  const ChainBuilderSheet({super.key});

  @override
  ConsumerState<ChainBuilderSheet> createState() => _ChainBuilderSheetState();
}

class _ChainBuilderSheetState extends ConsumerState<ChainBuilderSheet> {
  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitListProvider);
    final stacksAsync = ref.watch(stackListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgSurfaceRaised,
      appBar: AppBar(
        title: const Text('Chain Builder'),
        backgroundColor: Colors.transparent,
      ),
      body: habitsAsync.when(
        data: (habits) {
          return stacksAsync.when(
            data: (stacks) {
              final standaloneHabits = habits.where((h) => h.stackId == null).toList();
              
              final stackedMap = <String, List<Habit>>{};
              for (var s in stacks) {
                final sHabits = habits.where((h) => h.stackId == s.id.toString()).toList();
                sHabits.sort((a, b) => a.stackOrder.compareTo(b.stackOrder));
                if (sHabits.isNotEmpty) {
                  stackedMap[s.id.toString()] = sHabits;
                }
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Text(
                      'Drag a habit onto another to connect them into a stack. Drag it outside to unstack.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: DragTarget<Habit>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        final habit = details.data;
                        // Dropping in the empty space unstacks it
                        ref.read(stackNotifierProvider).moveHabitAfter(habit.id.toString(), null);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return ListView(
                          padding: const EdgeInsets.all(AppTheme.spacingXl),
                          children: [
                            // Render stacked
                            for (var s in stacks)
                              if (stackedMap.containsKey(s.id.toString()))
                                _BuilderStackRow(
                                  stackName: s.name,
                                  habits: stackedMap[s.id.toString()]!,
                                ),
                            
                            if (standaloneHabits.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacingXl),
                              Text('Standalone Habits', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppTheme.spacingMd),
                              for (var h in standaloneHabits)
                                _BuilderStackRow(stackName: null, habits: [h]),
                            ]
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _BuilderStackRow extends ConsumerWidget {
  final String? stackName;
  final List<Habit> habits;

  const _BuilderStackRow({required this.stackName, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stackName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(stackName!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            ),
          Row(
            children: habits.map((h) => _BuilderNode(habit: h)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BuilderNode extends ConsumerWidget {
  final Habit habit;

  const _BuilderNode({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeWidget = Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.bgBase,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderStrong, width: 2),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            habit.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );

    return DragTarget<Habit>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        return dragged.id != habit.id;
      },
      onAcceptWithDetails: (details) async {
        final dragged = details.data;
        final notifier = ref.read(stackNotifierProvider);
        
        // Cycle detection
        final hasCycle = await notifier.wouldCreateCycle(dragged.id.toString(), habit.id.toString());
        if (hasCycle) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This would create a loop — a habit can\'t come after itself in the chain.'),
                backgroundColor: AppTheme.accentRecoverFill,
              ),
            );
          }
          return;
        }

        await notifier.moveHabitAfter(dragged.id.toString(), habit.id.toString());
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<Habit>(
          data: habit,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              child: nodeWidget,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: nodeWidget,
          ),
          child: Container(
            color: candidateData.isNotEmpty ? AppTheme.accentGrowthFill.withValues(alpha: 0.2) : Colors.transparent,
            child: nodeWidget,
          ),
        );
      },
    );
  }
}
