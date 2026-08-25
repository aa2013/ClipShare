import 'package:clipshare/l10n/translation_key.dart';

enum TimeSpanUnit {
  day,
  hour,
  minute,
  second;

  int get magnification {
    switch (this) {
      case TimeSpanUnit.day:
        return 24 * 60 * 60;
      case TimeSpanUnit.hour:
        return 60 * 60;
      case TimeSpanUnit.minute:
        return 60;
      case TimeSpanUnit.second:
        return 1;
    }
  }

  String get label {
    switch (this) {
      case TimeSpanUnit.day:
        return TranslationKey.day.tr;
      case TimeSpanUnit.hour:
        return TranslationKey.hour.tr;
      case TimeSpanUnit.minute:
        return TranslationKey.minute.tr;
      case TimeSpanUnit.second:
        return TranslationKey.second.tr;
    }
  }

  static TimeSpanUnit parse(num value) {
    if (value < TimeSpanUnit.minute.magnification) {
      return TimeSpanUnit.second;
    }
    if (value < TimeSpanUnit.hour.magnification) {
      return TimeSpanUnit.minute;
    }
    if (value < TimeSpanUnit.day.magnification) {
      return TimeSpanUnit.hour;
    }
    return TimeSpanUnit.day;
  }
}
