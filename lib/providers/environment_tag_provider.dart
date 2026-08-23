import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/environment_tag.dart';

final environmentTagListProvider = StreamProvider<List<EnvironmentTag>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.environmentTags.where().watch(fireImmediately: true);
});

class EnvironmentTagNotifier {
  final Isar isar;

  EnvironmentTagNotifier(this.isar);

  Future<EnvironmentTag> getOrCreateTag(String label) async {
    final existing = await isar.environmentTags.filter().labelEqualTo(label).findFirst();
    if (existing != null) return existing;

    final newTag = EnvironmentTag()..label = label;

    await isar.writeTxn(() async {
      await isar.environmentTags.put(newTag);
    });
    return newTag;
  }
}

final environmentTagNotifierProvider = Provider<EnvironmentTagNotifier>((ref) {
  return EnvironmentTagNotifier(ref.watch(isarProvider));
});
