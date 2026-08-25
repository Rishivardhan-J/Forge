import 'package:isar/isar.dart';

part 'user_settings.g.dart';

@collection
class UserSettings {
  Id id = Isar.autoIncrement;

  String dayStartTime = "00:00";
  bool reduceMotion = false;
  bool listViewDefault = true;
  bool weeklyReviewEnabled = true;
  bool onboardingCompleted = false;

  UserSettings copyWith({
    String? dayStartTime,
    bool? reduceMotion,
    bool? listViewDefault,
    bool? weeklyReviewEnabled,
    bool? onboardingCompleted,
  }) {
    return UserSettings()
      ..id = id
      ..dayStartTime = dayStartTime ?? this.dayStartTime
      ..reduceMotion = reduceMotion ?? this.reduceMotion
      ..listViewDefault = listViewDefault ?? this.listViewDefault
      ..weeklyReviewEnabled = weeklyReviewEnabled ?? this.weeklyReviewEnabled
      ..onboardingCompleted = onboardingCompleted ?? this.onboardingCompleted;
  }
}
