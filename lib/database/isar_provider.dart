import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/consistency_score.dart';
import '../models/environment_tag.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_stack.dart';
import '../models/identity.dart';
import '../models/user_settings.dart';
import '../models/scorecard_entry.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

class DatabaseHelper {
  static Future<Isar> initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        HabitSchema,
        HabitLogSchema,
        HabitStackSchema,
        IdentitySchema,
        EnvironmentTagSchema,
        ConsistencyScoreSchema,
        UserSettingsSchema,
        ScorecardEntrySchema,
      ],
      directory: dir.path,
    );

    // Bootstrap UserSettings if it doesn't exist
    final count = await isar.userSettings.count();
    if (count == 0) {
      await isar.writeTxn(() async {
        await isar.userSettings.put(UserSettings());
      });
    }

    return isar;
  }
}
