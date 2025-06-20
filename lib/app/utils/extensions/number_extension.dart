extension NumberExt on num {
  bool between(num start, num end) {
    return this >= start && this <= end;
  }
}

extension IntExt on int {
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
