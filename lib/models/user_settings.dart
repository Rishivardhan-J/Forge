import 'package:isar/isar.dart';

part 'user_settings.g.dart';

enum AvatarAccent {
  teal,
  purple
}

@collection
class UserSettings {
  Id id = Isar.autoIncrement;

  String dayStartTime = "00:00";
  bool reduceMotion = false;
  bool listViewDefault = true;
  bool weeklyReviewEnabled = true;
  bool onboardingCompleted = false;

  String? displayName;
  
  @enumerated
  AvatarAccent avatarAccent = AvatarAccent.teal;

  UserSettings copyWith({
    String? dayStartTime,
    bool? reduceMotion,
    bool? listViewDefault,
    bool? weeklyReviewEnabled,
    bool? onboardingCompleted,
    String? displayName,
    AvatarAccent? avatarAccent,
  }) {
    return UserSettings()
      ..id = id
      ..dayStartTime = dayStartTime ?? this.dayStartTime
      ..reduceMotion = reduceMotion ?? this.reduceMotion
      ..listViewDefault = listViewDefault ?? this.listViewDefault
      ..weeklyReviewEnabled = weeklyReviewEnabled ?? this.weeklyReviewEnabled
      ..onboardingCompleted = onboardingCompleted ?? this.onboardingCompleted
      ..displayName = displayName ?? this.displayName
      ..avatarAccent = avatarAccent ?? this.avatarAccent;
  }
}
