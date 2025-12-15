import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/log.dart';

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
