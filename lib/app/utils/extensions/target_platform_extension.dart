import 'package:clipshare/app/data/enums/support_platform.dart';
import 'package:flutter/foundation.dart';

extension TargetPlatformExt on TargetPlatform {
  SupportPlatForm? toSupportPlatform(){
    switch(this){
      case TargetPlatform.android:
        return SupportPlatForm.android;
      case TargetPlatform.iOS:
        return SupportPlatForm.iOS;
      case TargetPlatform.linux:
        return SupportPlatForm.linux;
      case TargetPlatform.macOS:
        return SupportPlatForm.macos;
      case TargetPlatform.windows:
        return SupportPlatForm.windows;
      default:
        return null;
    }
  }
}
