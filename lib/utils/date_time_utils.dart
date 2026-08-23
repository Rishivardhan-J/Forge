import 'package:flutter/material.dart';

class DateTimeUtils {
  /// Resolves the "app today" based on the user's configured dayStartTime (e.g. "04:00").
  /// Returns a DateTime normalized to midnight of that logical day.
  static DateTime resolveAppToday(DateTime now, String dayStartTime) {
    final parts = dayStartTime.split(':');
    final startHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final startMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final appTime = TimeOfDay(hour: startHour, minute: startMinute);
    final nowTime = TimeOfDay.fromDateTime(now);

    final isBeforeStart = _timeOfDayToDouble(nowTime) < _timeOfDayToDouble(appTime);

    var appDate = DateTime(now.year, now.month, now.day);
    if (isBeforeStart) {
      appDate = appDate.subtract(const Duration(days: 1));
    }

    return appDate;
  }

  static double _timeOfDayToDouble(TimeOfDay tod) {
    return tod.hour + tod.minute / 60.0;
  }
}
