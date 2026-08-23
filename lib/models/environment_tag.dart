import 'package:isar/isar.dart';

part 'environment_tag.g.dart';

@collection
class EnvironmentTag {
  Id id = Isar.autoIncrement;

  late String label;
  String? locationGeopoint;
  String? photoPath;
}
