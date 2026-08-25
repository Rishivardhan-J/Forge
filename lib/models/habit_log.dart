import 'package:isar/isar.dart';

part 'habit_log.g.dart';

enum LogStatus { done, doneViaTwoMinute, missed, excused, notScheduled }

@collection
class HabitLog {
  Id id = Isar.autoIncrement;

  @Index()
  late String habitId;
  
  @Index()
  late DateTime date;

  @enumerated
  late LogStatus status;
  
  late DateTime loggedAt;
  bool isBackfilled = false;
  bool? environmentReady;
}
