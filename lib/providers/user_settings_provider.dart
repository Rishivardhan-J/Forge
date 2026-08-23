import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_provider.dart';
import '../models/user_settings.dart';

class UserSettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final isar = ref.watch(isarProvider);
    return isar.userSettings.where().findFirstSync() ?? UserSettings();
  }

  Future<void> updateSettings(UserSettings settings) async {
    // Optimistically update state so UI reacts instantly
    state = settings;
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.userSettings.put(settings);
    });
  }
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(() {
  return UserSettingsNotifier();
});
