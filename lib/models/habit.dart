import 'package:isar/isar.dart';

part 'habit.g.dart';

enum CueType { time, location, afterHabit }
enum FrequencyType { daily, specificWeekdays, timesPerWeek }

@embedded
class Frequency {
  @enumerated
  FrequencyType type = FrequencyType.daily;
  
  List<int>? weekdays;
  int? timesPerWeek;
}

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String name;
  
  @Index()
  String? identityStatementId;

  @enumerated
  late CueType cueType;
  late String cueValue;
  
  late String twoMinuteVersion;
  String? temptationBundle;
  
  @Index()
  String? environmentTagId;
  
  @Index()
  String? stackId;
  int stackOrder = 0;

  late Frequency frequency;
  
  DateTime? pausedUntil;
  late DateTime createdAt;
  bool isArchived = false;
}
