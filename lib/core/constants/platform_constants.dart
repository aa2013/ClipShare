import 'dart:io';

import 'package:clipshare/shared/extensions/string_extension.dart';

const windowsDirSeparate = '\\';

String get dirSeparate => Platform.isWindows ? windowsDirSeparate : unixDirSeparate;

final isAndroid = Platform.isAndroid;
final isWindows = Platform.isWindows;
final isLinux = Platform.isLinux;
final isMacOS = Platform.isMacOS;
final isIOS = Platform.isIOS;
final isDesktop = isWindows || isMacOS || isLinux;
final isMobile = !isDesktop;

String get startupExecutablePath {
  if (Platform.isLinux) {
    final appImagePath = Platform.environment['APPIMAGE'];
    if (appImagePath != null && appImagePath.isNotEmpty) {
      return appImagePath;
    }
  }
  return Platform.resolvedExecutable;
}
