import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/habit.dart';
import '../../models/habit_log.dart';
import '../../models/habit_stack.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stack_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/habit_utils.dart';
import '../widgets/add_edit_habit_sheet.dart';
import '../widgets/chain_builder_sheet.dart';
import '../widgets/transit_map_line.dart';

class HabitDetailScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(consistencyScoreProvider(habit.id.toString()));
    final logsAsync = ref.watch(habitLogsProvider(habit.id.toString()));
    final userSettings = ref.watch(userSettingsProvider);
    final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);

    // Compute last 7 days excluding today (from yesterday back to 7 days ago)
    final last7Days = List.generate(7, (index) => today.subtract(Duration(days: index + 1))).reversed.toList();

    // Fetch stack info for mini map
    final stacksAsync = ref.watch(stackListProvider);
    final habitsAsync = ref.watch(habitListProvider);
    
    HabitStack? currentStack;
    List<Habit> stackHabits = [];
    
    if (habit.stackId != null && stacksAsync.value != null && habitsAsync.value != null) {
      currentStack = stacksAsync.value!.where((s) => s.id.toString() == habit.stackId).firstOrNull;
      if (currentStack != null) {
        stackHabits = habitsAsync.value!.where((h) => h.stackId == currentStack!.id.toString()).toList();
        stackHabits.sort((a, b) => a.stackOrder.compareTo(b.stackOrder));
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Habit Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.linear_scale),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppTheme.bgSurfaceRaised,
                builder: (context) => const ChainBuilderSheet(),
              );
            },
            tooltip: 'Edit stack',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppTheme.bgSurfaceRaised,
                builder: (context) => AddEditHabitSheet(existingHabit: habit),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _confirmArchive(context, ref, currentStack),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        children: [
          if (currentStack != null && stackHabits.isNotEmpty) ...[
            TransitMapLine(
              stack: currentStack,
              habits: stackHabits,
              interactive: false,
              scale: 0.6,
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          
          Text(habit.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingLg),
          if (habit.identityStatementId != null) ...[
            Text('Identity linked', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTheme.spacingSm),
          ],
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Cue', value: _formatCue(habit)),
                  const SizedBox(height: AppTheme.spacingMd),
                  _InfoRow(label: '2-min version', value: habit.twoMinuteVersion),
                  if (habit.temptationBundle != null) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    _InfoRow(label: 'Temptation', value: habit.temptationBundle!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Score
          Center(
            child: scoreAsync.when(
              data: (scoreObj) {
                final scoreVal = scoreObj?.score ?? 0.0;
                return Text(
                  'Score: ${scoreVal.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.accentGrowthText),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading score'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Missed twice in a row prompt
          if (logsAsync.value != null) _buildMissedTwicePrompt(context, logsAsync.value!, today),

          const SizedBox(height: AppTheme.spacingXl),
          Text('Last 7 Days', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingLg),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: last7Days.map((date) {
              return _buildDayLogIndicator(context, ref, date, logsAsync.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedTwicePrompt(BuildContext context, List<HabitLog> logs, DateTime today) {
    int missesFound = 0;
    DateTime current = today.subtract(const Duration(days: 1));
    
    for (int i = 0; i < 7; i++) {
      if (!HabitUtils.isScheduledOn(habit, current)) {
        current = current.subtract(const Duration(days: 1));
        continue;
      }

      final log = logs.where((l) => l.date == current).firstOrNull;
      if (log?.status == LogStatus.missed || (log == null)) {
        missesFound++;
      } else if (log?.status == LogStatus.excused) {
        // Skip excused
      } else {
        break;
      }
      
      if (missesFound >= 2) break;
      current = current.subtract(const Duration(days: 1));
    }

    if (missesFound >= 2) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.accentRecoverFill.withOpacity(0.1),
          border: Border.all(color: AppTheme.accentRecoverFill),
          borderRadius: AppTheme.radiusCard,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRecoverText),
            const SizedBox(width: AppTheme.spacingLg),
            Expanded(
              child: Text(
                'Missed twice in a row — want to log the 2-minute version today?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.accentRecoverText),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDayLogIndicator(BuildContext context, WidgetRef ref, DateTime date, List<HabitLog>? logs) {
    final isScheduled = HabitUtils.isScheduledOn(habit, date);
    
    LogStatus? status;
    if (logs != null) {
      final log = logs.where((l) => l.date.year == date.year && l.date.month == date.month && l.date.day == date.day).firstOrNull;
      status = log?.status;
    }

    if (status == null && !isScheduled) {
      status = LogStatus.notScheduled;
    } else if (status == null) {
      status = LogStatus.missed;
    }

    Color color;
    switch (status) {
      case LogStatus.done:
      case LogStatus.doneViaTwoMinute:
        color = AppTheme.accentGrowthFill;
        break;
      case LogStatus.missed:
        color = AppTheme.accentRecoverFill;
        break;
      case LogStatus.notScheduled:
        color = AppTheme.textMuted.withOpacity(0.3);
        break;
      case LogStatus.excused:
        color = AppTheme.bgBase; 
        break;
    }

    final isExcused = status == LogStatus.excused;
    final isTooOld = date.isBefore(DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day));

    return GestureDetector(
      onTap: () {
        if (isTooOld) return; 
        _showBackfillChoice(context, ref, date);
      },
      child: Column(
        children: [
          Text(DateFormat('E').format(date).substring(0, 1), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isExcused ? Border.all(color: AppTheme.textSecondary, width: 2) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackfillChoice(BuildContext context, WidgetRef ref, DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        title: Text('Log for ${DateFormat('MMM d').format(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Done'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), date, LogStatus.done);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Done (2-min version)'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), date, LogStatus.doneViaTwoMinute);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Missed'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), date, LogStatus.missed);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Excused'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), date, LogStatus.excused);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCue(Habit habit) {
    switch (habit.cueType) {
      case CueType.time: return 'Time: ${habit.cueValue}';
      case CueType.location: return 'Location: ${habit.cueValue}';
      case CueType.afterHabit: return 'After: Habit ${habit.cueValue}';
    }
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, HabitStack? currentStack) {
    if (currentStack != null) {
      final index = currentStack.habitIds.indexOf(habit.id.toString());
      if (index > 0 && index < currentStack.habitIds.length - 1) {
        // Mid-stack archive
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgSurfaceRaised,
            title: const Text('Archive mid-stack habit?'),
            content: const Text('This habit is in the middle of a chain. What should happen to the rest of the chain?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(stackNotifierProvider).archiveHabitWithStackHandling(habit.id.toString(), split: true);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Split into two chains'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(stackNotifierProvider).archiveHabitWithStackHandling(habit.id.toString(), split: false);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Reconnect the chain', style: TextStyle(color: AppTheme.accentRecoverFill)),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Normal or edge archive
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        title: const Text('Archive Habit?'),
        content: const Text('This habit will be hidden. It can be restored later in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(stackNotifierProvider).archiveHabitWithStackHandling(habit.id.toString(), split: false);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: const Text('Archive', style: TextStyle(color: AppTheme.accentRecoverFill)),
          ),
        ],
      ),
    );
  }
}
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
