import 'dart:ui';

extension SizeExtension on Size {
  String get str {
    return '${width.toInt()}x${height.toInt()}';
  }
}
