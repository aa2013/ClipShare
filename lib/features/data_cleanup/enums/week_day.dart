import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/log.dart';

/// 一周星期枚举，[value] 为 UnixCron 星期位取值（周日 0，周一 1 …… 周六 6）。
enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// UnixCron 星期位取值
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

  /// 本地化星期名称
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

  /// 按 UnixCron 星期位取值解析，未知值抛出异常
  static WeekDay parse(int value) {
    return WeekDay.values.firstWhere(
      (e) => e.value == value,
      orElse: () {
        logger.debug('WeekDay', "key '$value' unknown");
        throw Exception('Unknown WeekDay value: $value');
      },
    );
  }
}
