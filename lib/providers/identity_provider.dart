import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/identity.dart';

final identityListProvider = StreamProvider<List<Identity>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.identitys.where().watch(fireImmediately: true);
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
