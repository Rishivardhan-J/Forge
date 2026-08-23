import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/user_settings.dart';

final userSettingsProvider = Provider<UserSettings>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.userSettings.where().findFirstSync() ?? UserSettings();
});

class UserSettingsNotifier {
  final Isar isar;
  
  UserSettingsNotifier(this.isar);
  
  Future<void> updateSettings(UserSettings settings) async {
    await isar.writeTxn(() async {
      await isar.userSettings.put(settings);
    });
  }
}

final userSettingsNotifierProvider = Provider<UserSettingsNotifier>((ref) {
  return UserSettingsNotifier(ref.watch(isarProvider));
});
