import 'package:clipshare/app/utils/extensions/string_extension.dart';

enum SupportPlatForm {
  android,
  iOS,
  linux,
  macos,
  windows;

  @override
  String toString() {
    return name.upperFirst;
  }
}
