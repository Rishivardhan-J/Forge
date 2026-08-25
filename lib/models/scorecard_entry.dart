import 'package:isar/isar.dart';

part 'scorecard_entry.g.dart';

enum ScorecardVerdict {
  positive,
  negative,
  neutral
}

@collection
class ScorecardEntry {
  Id id = Isar.autoIncrement;

  late String label;

  @enumerated
  late ScorecardVerdict verdict;

  DateTime createdAt = DateTime.now();
}
