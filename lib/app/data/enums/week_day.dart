import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/log.dart';

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  int get value {
    switch (this) {
      case WeekDay.monday:
        return 1;
      case WeekDay.tuesday:
        return 2;
      case WeekDay.wednesday:
        return 3;
      case WeekDay.thursday:
        return 4;
      case WeekDay.friday:
        return 5;
      case WeekDay.saturday:
        return 6;
      case WeekDay.sunday:
        return 0;
    }
  }

  String get label {
    switch (this) {
      case WeekDay.monday:
        return TranslationKey.monday.tr;
      case WeekDay.tuesday:
        return TranslationKey.tuesday.tr;
      case WeekDay.wednesday:
        return TranslationKey.wednesday.tr;
      case WeekDay.thursday:
        return TranslationKey.thursday.tr;
      case WeekDay.friday:
        return TranslationKey.friday.tr;
      case WeekDay.saturday:
        return TranslationKey.saturday.tr;
      case WeekDay.sunday:
        return TranslationKey.sunday.tr;
    }
  }

  static WeekDay parse(int value) {
    return WeekDay.values.firstWhere(
      (e) => e.value == value,
      orElse: () {
        logger.debug("WeekDay", "key '$value' unknown");
        throw Exception("Unknown WeekDay value: $value");
      },
    );
  }
}
