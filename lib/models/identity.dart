import 'package:isar/isar.dart';

part 'identity.g.dart';

@collection
class Identity {
  Id id = Isar.autoIncrement;

  late String statement;
  late List<String> linkedHabitIds;

  @ignore
  int get voteCount => linkedHabitIds.length;
}
