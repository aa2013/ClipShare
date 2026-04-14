import 'dart:io';

extension PlatformExt on Platform {
  static bool get isMobile {
    return Platform.isIOS || Platform.isAndroid;
  }

  static bool get isDesktop {
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  static String get startupExecutablePath {
    if (Platform.isLinux) {
      final appImagePath = Platform.environment['APPIMAGE'];
      if (appImagePath != null && appImagePath.isNotEmpty) {
        return appImagePath;
      }
    }
    return Platform.resolvedExecutable;
  }
}
