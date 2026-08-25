import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/identity.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

final identityListProvider = StreamProvider<List<Identity>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.identitys.where().watch(fireImmediately: true);
});

final identityVoteCountProvider = StreamProvider.family<int, String>((ref, identityId) {
  final isar = ref.watch(isarProvider);
  return isar.identitys.filter().idEqualTo(int.parse(identityId)).watch(fireImmediately: true).asyncMap((identities) async {
    if (identities.isEmpty) return 0;
    final identity = identities.first;
    
    final habits = await isar.habits.filter().isArchivedEqualTo(false).findAll();
    final nonArchivedLinked = identity.linkedHabitIds.where((id) => habits.any((h) => h.id.toString() == id)).toList();

    if (nonArchivedLinked.isEmpty) return 0;
    
    final count = await isar.habitLogs.filter()
      .anyOf(nonArchivedLinked, (q, String habitId) => q.habitIdEqualTo(habitId))
      .and()
      .group((q) => q.statusEqualTo(LogStatus.done).or().statusEqualTo(LogStatus.doneViaTwoMinute))
      .count();
      
    return count;
  });
});

class EvidenceLogEntry {
  final HabitLog log;
  final Habit habit;
  EvidenceLogEntry(this.log, this.habit);
}

final evidenceLogProvider = StreamProvider.family<List<EvidenceLogEntry>, String>((ref, identityId) {
  final isar = ref.watch(isarProvider);
  return isar.identitys.filter().idEqualTo(int.parse(identityId)).watch(fireImmediately: true).asyncMap((identities) async {
    if (identities.isEmpty) return [];
    final identity = identities.first;
    
    final habits = await isar.habits.filter().isArchivedEqualTo(false).findAll();
    final nonArchivedLinked = identity.linkedHabitIds.where((id) => habits.any((h) => h.id.toString() == id)).toList();

    if (nonArchivedLinked.isEmpty) return [];
    
    final logs = await isar.habitLogs.filter()
      .anyOf(nonArchivedLinked, (q, String habitId) => q.habitIdEqualTo(habitId))
      .and()
      .group((q) => q.statusEqualTo(LogStatus.done).or().statusEqualTo(LogStatus.doneViaTwoMinute))
      .sortByDateDesc()
      .findAll();
      
    return logs.map((log) {
      final habit = habits.firstWhere((h) => h.id.toString() == log.habitId);
      return EvidenceLogEntry(log, habit);
    }).toList();
  });
});

class IdentityNotifier {
  final Isar isar;

  IdentityNotifier(this.isar);

  Future<Identity> getOrCreateIdentity(String statement) async {
    final existing = await isar.identitys.filter().statementEqualTo(statement).findFirst();
    if (existing != null) return existing;

    final newIdentity = Identity()
      ..statement = statement
      ..linkedHabitIds = [];

    await isar.writeTxn(() async {
      await isar.identitys.put(newIdentity);
    });
    return newIdentity;
  }
}

final identityNotifierProvider = Provider<IdentityNotifier>((ref) {
  return IdentityNotifier(ref.watch(isarProvider));
});
