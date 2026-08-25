import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/identity.dart';
import '../../models/habit_log.dart';
import '../../providers/identity_provider.dart';
import '../../theme/app_theme.dart';

class EvidenceLogSheet extends ConsumerWidget {
  final Identity identity;

  const EvidenceLogSheet({super.key, required this.identity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidenceAsync = ref.watch(evidenceLogProvider(identity.id.toString()));

    return Scaffold(
      backgroundColor: AppTheme.bgSurfaceRaised,
      appBar: AppBar(
        title: const Text('Evidence Log'),
        backgroundColor: Colors.transparent,
      ),
      body: evidenceAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  'No votes logged yet for this identity.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isTwoMinute = entry.log.status == LogStatus.doneViaTwoMinute;

              return Container(
                key: ValueKey('${entry.log.habitId}_${entry.log.date.toIso8601String()}'),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.bgBase,
                  borderRadius: AppTheme.radiusCard,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.habit.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMd().format(entry.log.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isTwoMinute)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderDefault),
                        ),
                        child: Text(
                          '2-min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
