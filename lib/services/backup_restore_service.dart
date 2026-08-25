import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/isar_provider.dart';
import '../models/consistency_score.dart';
import '../models/environment_tag.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/habit_stack.dart';
import '../models/identity.dart';
import '../models/scorecard_entry.dart';
import '../models/user_settings.dart';

class BackupRestoreService {
  static Future<bool> backupData(Isar isar) async {
    try {
      final data = <String, dynamic>{};
      
      data['habits'] = await isar.habits.where().exportJson();
      data['habitLogs'] = await isar.habitLogs.where().exportJson();
      data['habitStacks'] = await isar.habitStacks.where().exportJson();
      data['identities'] = await isar.identitys.where().exportJson();
      data['environmentTags'] = await isar.environmentTags.where().exportJson();
      data['consistencyScores'] = await isar.consistencyScores.where().exportJson();
      data['userSettings'] = await isar.userSettings.where().exportJson();
      data['scorecardEntries'] = await isar.scorecardEntrys.where().exportJson();

      final jsonString = jsonEncode(data);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/forge_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Forge Backup',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Backup failed: $e');
      return false;
    }
  }

  static Future<bool> restoreData(Isar isar) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.isNotEmpty && result.single.path != null) {
        final file = File(result.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        await isar.writeTxn(() async {
          await isar.clear();
          
          if (data['habits'] != null) await isar.habits.importJson(List<Map<String, dynamic>>.from(data['habits']));
          if (data['habitLogs'] != null) await isar.habitLogs.importJson(List<Map<String, dynamic>>.from(data['habitLogs']));
          if (data['habitStacks'] != null) await isar.habitStacks.importJson(List<Map<String, dynamic>>.from(data['habitStacks']));
          if (data['identities'] != null) await isar.identitys.importJson(List<Map<String, dynamic>>.from(data['identities']));
          if (data['environmentTags'] != null) await isar.environmentTags.importJson(List<Map<String, dynamic>>.from(data['environmentTags']));
          if (data['consistencyScores'] != null) await isar.consistencyScores.importJson(List<Map<String, dynamic>>.from(data['consistencyScores']));
          if (data['userSettings'] != null) await isar.userSettings.importJson(List<Map<String, dynamic>>.from(data['userSettings']));
          if (data['scorecardEntries'] != null) await isar.scorecardEntrys.importJson(List<Map<String, dynamic>>.from(data['scorecardEntries']));
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Restore failed: $e');
      return false;
    }
  }
}
