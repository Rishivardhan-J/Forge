import 'package:isar/isar.dart';

part 'habit_stack.g.dart';

@collection
class HabitStack {
  Id id = Isar.autoIncrement;

  late String name;
  late List<String> habitIds;
}
