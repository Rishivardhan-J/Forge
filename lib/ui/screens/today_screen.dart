import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/habit.dart';
import '../../models/habit_log.dart';
import '../../providers/habit_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/habit_utils.dart';
import '../../providers/stack_provider.dart';
import '../widgets/add_edit_habit_sheet.dart';
import '../widgets/transit_map_line.dart';
import 'habit_detail_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final userSettings = ref.watch(userSettingsProvider);
    final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);

    final stacksAsync = ref.watch(stackListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState(context);
          }

          final screenReaderActive = MediaQuery.accessibleNavigationOf(context);
          final showListView = screenReaderActive || userSettings.listViewDefault;

          if (showListView) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              itemCount: habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingLg),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isScheduled = HabitUtils.isScheduledOn(habit, today);
                return _HabitRow(
                  habit: habit,
                  isScheduled: isScheduled,
                  todayDate: today,
                );
              },
            );
          } else {
            // Transit Map Mode
            return stacksAsync.when(
              data: (stacks) {
                // Group habits by stack
                final standaloneHabits = habits.where((h) => h.stackId == null).toList();
                
                final stackedMap = <String, List<Habit>>{};
                for (var s in stacks) {
                  final sHabits = habits.where((h) => h.stackId == s.id.toString()).toList();
                  sHabits.sort((a, b) => a.stackOrder.compareTo(b.stackOrder));
                  if (sHabits.isNotEmpty) {
                    stackedMap[s.id.toString()] = sHabits;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Render stacked
                      for (var s in stacks)
                        if (stackedMap.containsKey(s.id.toString()))
                          TransitMapLine(stack: s, habits: stackedMap[s.id.toString()]!),
                      
                      // Render standalone
                      for (var h in standaloneHabits)
                        TransitMapLine(stack: null, habits: [h]),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading stacks: $err')),
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.textPrimary))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGrowthFill,
        foregroundColor: AppTheme.textPrimary,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: AppTheme.bgSurfaceRaised,
            builder: (context) => const AddEditHabitSheet(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 100,
            child: CustomPaint(
              painter: _EmptyStatePainter(),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2xl),
          Text(
            'Lay your first track',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGrowthFill,
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusButton),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppTheme.bgSurfaceRaised,
                builder: (context) => const AddEditHabitSheet(),
              );
            },
            child: const Text('Add a habit'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = AppTheme.borderStrong
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = AppTheme.accentGrowthFill.withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final stationPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
    
    final stationBorderPaint = Paint()
      ..color = AppTheme.borderStrong
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw track
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), trackPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * 0.4, size.height / 2), progressPaint);

    // Draw stations
    canvas.drawCircle(Offset(size.width * 0.2, size.height / 2), 12, stationPaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height / 2), 12, stationBorderPaint);

    canvas.drawCircle(Offset(size.width * 0.8, size.height / 2), 12, stationPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height / 2), 12, stationBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HabitRow extends ConsumerWidget {
  final Habit habit;
  final bool isScheduled;
  final DateTime todayDate;

  const _HabitRow({
    required this.habit,
    required this.isScheduled,
    required this.todayDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(habitLogsProvider(habit.id.toString()));
    
    // Resolve today's status
    LogStatus? todayStatus;
    if (logsAsync.value != null) {
      final log = logsAsync.value!.where((l) {
        return l.date.year == todayDate.year && l.date.month == todayDate.month && l.date.day == todayDate.day;
      }).firstOrNull;
      todayStatus = log?.status;
    }

    // Default to notScheduled if not scheduled and no log exists
    if (todayStatus == null && !isScheduled) {
      todayStatus = LogStatus.notScheduled;
    }

    final opacity = isScheduled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () {
          if (!isScheduled && todayStatus == LogStatus.notScheduled) {
            // Unscheduled and no log -> navigate to detail, do not show log choice
            Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
            return;
          }
          // Primary logging action
          _showLogChoice(context, ref);
        },
        onLongPress: () {
          // Secondary action: Excused
          _logStatus(context, ref, LogStatus.excused);
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          _formatCue(habit),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                _StatusIndicator(status: todayStatus),
              ],
            ),
          ),
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

  void _showLogChoice(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        title: const Text('Log today'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Done'),
              onTap: () {
                _logStatus(context, ref, LogStatus.done);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Done (2-min version)'),
              onTap: () {
                _logStatus(context, ref, LogStatus.doneViaTwoMinute);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Missed'),
              onTap: () {
                _logStatus(context, ref, LogStatus.missed);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logStatus(BuildContext context, WidgetRef ref, LogStatus status) {
    ref.read(habitNotifierProvider).logHabit(habit.id.toString(), todayDate, status);
    if (status == LogStatus.missed) {
      HabitUtils.showEnvironmentReadyPrompt(context, ref, habit, todayDate);
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final LogStatus? status;

  const _StatusIndicator({this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.transparent;
    Widget? icon;

    switch (status) {
      case LogStatus.done:
      case LogStatus.doneViaTwoMinute:
        color = AppTheme.accentGrowthFill;
        icon = const Icon(Icons.check, size: 16, color: AppTheme.bgBase);
        break;
      case LogStatus.missed:
        color = AppTheme.accentRecoverFill;
        icon = const Icon(Icons.close, size: 16, color: AppTheme.bgBase);
        break;
      case LogStatus.excused:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.textSecondary, width: 2),
          ),
          child: const Icon(Icons.remove, size: 16, color: AppTheme.textSecondary),
        );
      case LogStatus.notScheduled:
        color = AppTheme.textMuted.withValues(alpha: 0.3);
        break;
      case null:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderStrong, width: 2),
          ),
        );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: icon,
    );
  }
}
