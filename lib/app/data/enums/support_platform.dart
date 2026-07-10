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
    switch (this) {
      case SupportPlatForm.android:
        return 'Android';
      case SupportPlatForm.iOS:
        return 'iOS';
      case SupportPlatForm.linux:
        return 'Linux';
      case SupportPlatForm.macos:
        return 'macOS';
      case SupportPlatForm.windows:
        return 'Windows';
    }
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
