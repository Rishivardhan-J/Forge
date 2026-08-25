import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/identity.dart';
import '../../providers/identity_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/evidence_log_sheet.dart';
import 'habit_detail_screen.dart';

class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identitiesAsync = ref.watch(identityListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Identity'),
        backgroundColor: AppTheme.bgBase,
      ),
      body: identitiesAsync.when(
        data: (identities) {
          if (identities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Text(
                  'Create a habit with an identity statement to see it here.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            itemCount: identities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 100),
            itemBuilder: (context, index) {
              return _IdentityOrbitSystem(identity: identities[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _IdentityOrbitSystem extends ConsumerStatefulWidget {
  final Identity identity;

  const _IdentityOrbitSystem({super.key, required this.identity});

  @override
  ConsumerState<_IdentityOrbitSystem> createState() => _IdentityOrbitSystemState();
}

class _IdentityOrbitSystemState extends ConsumerState<_IdentityOrbitSystem> with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // fixed base period
    );
    // reduceMotion check moved to build via listen
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.identity;
    final voteCountAsync = ref.watch(identityVoteCountProvider(identity.id.toString()));
    final reduceMotion = ref.watch(userSettingsProvider).reduceMotion;
    
    ref.listen(userSettingsProvider, (previous, next) {
      if (next.reduceMotion && _orbitController.isAnimating) {
        _orbitController.stop();
      } else if (!next.reduceMotion && !_orbitController.isAnimating) {
        _orbitController.repeat();
      }
    });

    if (!reduceMotion && !_orbitController.isAnimating) {
      _orbitController.repeat();
    } else if (reduceMotion && _orbitController.isAnimating) {
      _orbitController.stop();
    }

    // Core circle size based on voteCount. Clamped between 60 and 150.
    final voteCount = voteCountAsync.value ?? 0;
    final coreSize = (60.0 + (voteCount * 2.0)).clamp(60.0, 150.0);
    final orbitRadius = coreSize / 2 + 50.0;

    return Column(
      children: [
        SizedBox(
          height: orbitRadius * 2 + 40, // padding for glowing nodes
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Core Circle
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: AppTheme.bgSurfaceRaised,
                    builder: (context) => EvidenceLogSheet(identity: identity),
                  );
                },
                child: Container(
                  width: coreSize,
                  height: coreSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentIdentityFill.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.accentIdentityFill, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      voteCount.toString(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.accentIdentityFill,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),

              // Orbiting Nodes
              ...List.generate(identity.linkedHabitIds.length, (index) {
                final habitId = identity.linkedHabitIds[index];
                final initialAngle = (360 / identity.linkedHabitIds.length) * index;
                
                return _OrbitingNode(
                  key: ValueKey(habitId),
                  habitId: habitId,
                  orbitRadius: orbitRadius,
                  initialAngle: initialAngle * (pi / 180),
                  controller: _orbitController,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          identity.statement,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrbitingNode extends ConsumerWidget {
  final String habitId;
  final double orbitRadius;
  final double initialAngle;
  final AnimationController controller;

  const _OrbitingNode({
    super.key,
    required this.habitId,
    required this.orbitRadius,
    required this.initialAngle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).value;
    final habit = habits?.where((h) => h.id.toString() == habitId).firstOrNull;
    
    if (habit == null || habit.isArchived) return const SizedBox();

    final scoreVal = ref.watch(consistencyScoreProvider(habitId)).value?.score ?? 0.0;
    
    final durationSeconds = 60.0 - (scoreVal / 100) * (60.0 - 12.0);
    final speedMultiplier = 60.0 / durationSeconds;
    
    final opacity = 0.3 + (scoreVal / 100) * 0.7;
    final blurRadius = (scoreVal / 100) * 12.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final currentAngle = initialAngle + (controller.value * speedMultiplier * 2 * pi) % (2 * pi);
        final dx = cos(currentAngle) * orbitRadius;
        final dy = sin(currentAngle) * orbitRadius;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Semantics(
            label: 'Habit: ${habit.name}, Consistency Score: ${scoreVal.round()}%',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HabitDetailScreen(habit: habit)),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentIdentityFill.withValues(alpha: opacity),
                    boxShadow: blurRadius > 0
                        ? [
                            BoxShadow(
                              color: AppTheme.accentIdentityFill.withValues(alpha: opacity),
                              blurRadius: blurRadius,
                              spreadRadius: blurRadius / 2,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
