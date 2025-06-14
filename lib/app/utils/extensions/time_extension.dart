import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:intl/intl.dart' as intl;

extension DateTimeExt on DateTime {
  String format([String format = "yyyy-MM-dd HH:mm:ss"]) {
    return intl.DateFormat(format).format(this);
  }

  String get simpleStr {
    String time = "";
    DateTime now = DateTime.now();
    Duration difference = now.difference(this);

    if (difference.inMinutes < 1) {
      time = TranslationKey.moment.tr;
    } else if (difference.inHours < 1) {
      int minutes = difference.inMinutes;
      time = "$minutes${TranslationKey.minutesAgo.tr}";
    } else if (difference.inHours < 24) {
      int hours = difference.inHours;
      time = "$hours${TranslationKey.hoursAgo.tr}";
    } else {
      time = toString().substring(0, 19); // 使用默认的日期时间格式
    }
    return time;
  }

  bool isWithinRange(Duration duration, [DateTime? other]) {
    other ??= DateTime.now();
    var micros = other.difference(this).inMicroseconds;
    return micros.abs() < duration.inMicroseconds;
  }
}
