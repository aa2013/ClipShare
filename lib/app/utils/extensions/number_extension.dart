import 'package:clipshare/app/data/enums/time_span_unit.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/cupertino.dart';

extension NumberExt on num {
  static final _insetsMap = <String, EdgeInsets>{};
  static final _radiusMap = <String, Radius>{};

  bool between(num start, num end) {
    return this >= start && this <= end;
  }

  String get timeSpanStr {
    if (this < TimeSpanUnit.minute.magnification) {
      return '$this ${TranslationKey.second.tr}';
    }
    if (this < TimeSpanUnit.hour.magnification) {
      var val = this / TimeSpanUnit.minute.magnification;
      var valStr = '';
      if ("${val.toInt()}.0" == val.toString()) {
        valStr = val.toInt().toString();
      } else {
        valStr = val.toStringAsFixed(1);
      }
      return '$valStr ${TranslationKey.minute.tr}';
    }
    if (this < TimeSpanUnit.day.magnification) {
      var val = this / TimeSpanUnit.hour.magnification;
      var valStr = '';
      if ("${val.toInt()}.0" == val.toString()) {
        valStr = val.toInt().toString();
      } else {
        valStr = val.toStringAsFixed(1);
      }
      return '$valStr ${TranslationKey.hour.tr}';
    }
    var val = this / TimeSpanUnit.day.magnification;
    var valStr = '';
    if ("${val.toInt()}.0" == val.toString()) {
      valStr = val.toInt().toString();
    } else {
      valStr = val.toStringAsFixed(1);
    }
    return '$valStr ${TranslationKey.day.tr}';
  }

  EdgeInsets get insetAll => _insetsMap.putIfAbsent(
    'insetAll_$this',
        () => EdgeInsets.all(toDouble()),
  );

  EdgeInsets get insetH => _insetsMap.putIfAbsent(
    'insetH_$this',
        () => EdgeInsets.symmetric(horizontal: toDouble()),
  );

  EdgeInsets get insetV => _insetsMap.putIfAbsent(
    'insetV_$this',
        () => EdgeInsets.symmetric(vertical: toDouble()),
  );

  EdgeInsets get insetL => _insetsMap.putIfAbsent(
    'insetL_$this',
        () => EdgeInsets.only(left: toDouble()),
  );

  EdgeInsets get insetT => _insetsMap.putIfAbsent(
    'insetT_$this',
        () => EdgeInsets.only(top: toDouble()),
  );

  EdgeInsets get insetR => _insetsMap.putIfAbsent(
    'insetR_$this',
        () => EdgeInsets.only(right: toDouble()),
  );

  EdgeInsets get insetB => _insetsMap.putIfAbsent(
    'insetB_$this',
        () => EdgeInsets.only(bottom: toDouble()),
  );

  EdgeInsets insetHV({double? horizontal, double? vertical}) {
    final key = 'insetHV_${horizontal ?? this}_${vertical ?? this}';
    return _insetsMap.putIfAbsent(
      key,
          () => EdgeInsets.symmetric(
        horizontal: horizontal ?? toDouble(),
        vertical: vertical ?? toDouble(),
      ),
    );
  }

  Radius get r => _radiusMap.putIfAbsent("all_$this", () => Radius.circular(toDouble()));
}

extension IntExt on int {
  static final _durationMap = <int, Duration>{};

  String get sizeStr {
    if (this < 0) {
      return '-';
    }
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (this >= gb) {
      return '${(this / gb).toStringAsFixed(2)} GB';
    } else if (this >= mb) {
      return '${(this / mb).toStringAsFixed(2)} MB';
    } else if (this >= kb) {
      return '${(this / kb).toStringAsFixed(2)} KB';
    } else {
      return '$this B';
    }
  }

  String get to24HFormatStr {
    // 计算天、小时、分钟、秒
    int days = this ~/ (24 * 3600);
    int hours = (this % (24 * 3600)) ~/ 3600;
    int minutes = (this % 3600) ~/ 60;
    int seconds = this % 60;

    // 构造时间字符串
    StringBuffer timeString = StringBuffer();

    // 如果时间表示需要到天和小时
    if (days > 0) {
      timeString.write('$days 天 ');
    }
    if (days > 0 || hours > 0) {
      timeString.write('${hours.toString().padLeft(2, '0')}:');
    }
    timeString.write('${minutes.toString().padLeft(2, '0')}:');
    timeString.write(seconds.toString().padLeft(2, '0'));

    return timeString.toString();
  }

  Duration get s {
    final ms = this * 1000;
    return _durationMap.putIfAbsent(
      ms,
      () => Duration(milliseconds: ms.toInt()),
    );
  }

  Duration get ms => _durationMap.putIfAbsent(
    this,
    () => Duration(milliseconds: toInt()),
  );

  Duration get min {
    final ms = this * 60 * 1000;
    return _durationMap.putIfAbsent(
      ms,
      () => Duration(milliseconds: ms.toInt()),
    );
  }

}

extension DoubleExt on double {
  String get sizeStr {
    if (this < 0) {
      return '-';
    }
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (this >= gb) {
      return '${(this / gb).toStringAsFixed(2)} GB';
    } else if (this >= mb) {
      return '${(this / mb).toStringAsFixed(2)} MB';
    } else if (this >= kb) {
      return '${(this / kb).toStringAsFixed(2)} KB';
    } else {
      return '$this B';
    }
  }
}
