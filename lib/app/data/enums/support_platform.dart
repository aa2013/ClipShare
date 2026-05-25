import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

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
  IconData get icon{
    switch(this){
      case SupportPlatForm.android:
        return SimpleIcons.android;
      case SupportPlatForm.iOS:
        return SimpleIcons.ios;
      case SupportPlatForm.linux:
        return SimpleIcons.linux;
      case SupportPlatForm.macos:
        return SimpleIcons.macos;
      case SupportPlatForm.windows:
        return Icons.laptop_windows_outlined;
    }
  }
}
