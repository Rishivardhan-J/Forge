import 'package:isar/isar.dart';

part 'user_settings.g.dart';

@collection
class UserSettings {
  Id id = Isar.autoIncrement;

  String dayStartTime = "00:00";
  bool reduceMotion = false;
  bool listViewDefault = true;
}
