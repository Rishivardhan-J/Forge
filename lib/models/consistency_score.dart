import 'package:isar/isar.dart';

part 'consistency_score.g.dart';

@collection
class ConsistencyScore {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String habitId;
  
  late double score;
  late DateTime lastUpdated;
}
