import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../models/habit.dart';
import '../../models/habit_log.dart';
import '../../providers/habit_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/habit_utils.dart';
import '../widgets/transit_map_line.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(insightsOverviewProvider);
    final userSettings = ref.watch(userSettingsProvider);
    final today = DateTimeUtils.resolveAppToday(DateTime.now(), userSettings.dayStartTime);
    final habitsAsync = ref.watch(habitListProvider);
    final reduceMotion = userSettings.reduceMotion;

    String headerText = 'Dashboard';
    if (overviewAsync.value?.strongestIdentityStatement != null) {
      headerText = overviewAsync.value!.strongestIdentityStatement!;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: Text(headerText),
        backgroundColor: AppTheme.bgBase,
        elevation: 0,
      ),
      body: overviewAsync.when(
        data: (overview) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroRing(context, overview.averageConsistency, reduceMotion, overview.hasHistory),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                child: habitsAsync.when(
                  data: (habits) => _buildTodayAtAGlance(context, ref, habits, today),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overview.strongestIdentityStatement != null) ...[
                      Text(
                        "${overview.strongestIdentityStatement} — ${overview.strongestIdentityVotes} votes",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],
                    if (overview.mostConsistentHabitName != null) ...[
                      Text(
                        "${overview.mostConsistentHabitName} is your most consistent habit right now, at ${overview.mostConsistentHabitScore.toStringAsFixed(1)}.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],
                    Text(
                      overview.weekOverWeekSentence,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 64)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentGrowthFill)),
        error: (e, st) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeroRing(BuildContext context, double consistency, bool reduceMotion, bool hasHistory) {
    return Padding(
      padding: const EdgeInsets.only(top: 48.0, bottom: 48.0),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: consistency),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: value / 100.0,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.borderStrong,
                    color: AppTheme.accentGrowthFill,
                  ),
                  if (!hasHistory)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                        child: Text(
                          "Lay your first track to build consistency.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: FittedBox(
                        child: Text(
                          value.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAtAGlance(BuildContext context, WidgetRef ref, List<Habit> habits, DateTime today) {
    final scheduledHabits = habits.where((h) => !h.isArchived && HabitUtils.isScheduledOn(h, today)).toList();
    if (scheduledHabits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today at a glance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            "No habits scheduled for today.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today at a glance',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: scheduledHabits.map((habit) {
              return _buildHabitDot(context, ref, habit, today);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitDot(BuildContext context, WidgetRef ref, Habit habit, DateTime today) {
    final logsAsync = ref.watch(habitLogsProvider(habit.id.toString()));
    
    return logsAsync.when(
      data: (logs) {
        final todayLog = logs.where((l) => l.date.year == today.year && l.date.month == today.month && l.date.day == today.day).firstOrNull;
        final status = todayLog?.status ?? LogStatus.missed;

        String statusLabel = 'unlogged';
        if (status == LogStatus.done || status == LogStatus.doneViaTwoMinute) statusLabel = 'completed';
        if (status == LogStatus.missed) statusLabel = 'missed';
        if (status == LogStatus.excused) statusLabel = 'excused';

        final semanticsLabel = '${habit.name}, $statusLabel';

        return Padding(
          padding: const EdgeInsets.only(right: AppTheme.spacingMd),
          child: Semantics(
            label: semanticsLabel,
            button: true,
            child: GestureDetector(
              onTap: () => _showLogChoice(context, ref, habit, today),
              child: StationNode(
                status: status,
                accentColor: AppTheme.accentGrowthFill,
                size: 24,
              ),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(right: AppTheme.spacingMd),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGrowthFill)),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  void _showLogChoice(BuildContext context, WidgetRef ref, Habit habit, DateTime todayDate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurfaceRaised,
        title: Text('Log: ${habit.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Done'),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), todayDate, LogStatus.done);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Done (2-min version)'),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), todayDate, LogStatus.doneViaTwoMinute);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Missed'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), todayDate, LogStatus.missed);
                HabitUtils.showEnvironmentReadyPrompt(context, ref, habit, todayDate);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Excused'),
              onTap: () {
                ref.read(habitNotifierProvider).logHabit(habit.id.toString(), todayDate, LogStatus.excused);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
