import 'dart:convert';

import 'package:clipshare/core/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

//app名称
const String appName = 'ClipShare';
const appPkg = 'top.coclyun.clipshare';
const appIconSize = 17.0;
const minVersion = AppVersion('1.5.0', '27');

///Android 历史记录悬浮窗把手默认颜色
const int defaultHistoryFloatHandleColor = 0x17FFFFFF;

///Android 历史记录悬浮窗把手默认宽度
const int defaultHistoryFloatHandleWidth = 32;

//Windows上使用，与项目中的 windows/packaging.exe/make_config.yaml 保持一致
const String appGuid = 'B72665DE-3DB5-B0E9-0EF9-55CCB65D3D62';

// Windows 正式安装版 Toast 应用身份，需与 Inno Setup 快捷方式的 AppUserModelID 保持一致。
const String windowsAppUserModelId = appPkg;
// Windows 开发运行使用独立 Toast 应用身份，避免覆盖正式安装版的通知图标注册信息。
const String windowsDevAppUserModelId = '$windowsAppUserModelId.dev';
//数据广播Action
const kOnHistoryChangedBroadcastAction = '$appPkg.ACTION_ON_HISTORY_CHANGED';

const double macOSSafeAreaHeight = 25;

const androidRootStoragePath = '/storage/emulated/0';
const androidDownloadPath = '$androidRootStoragePath/Download';
const androidPicturesPath = '$androidRootStoragePath/Pictures';
const androidDocumentsPath = '$androidRootStoragePath/Documents';
const androidDataPath = '/storage/emulated/0/Android/data';
const iosPIPDefaultVideoPath = 'assets/videos/pip_example.mp4';
const windowsStartUpPath = r'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup';

//配对时限（秒）
const pairingLimit = 60;
const channelCommon = '$appPkg/common';
const channelClip = '$appPkg/clip';
const channelAndroid = '$appPkg/android';
const androidReadFileEventChannel = '$appPkg/read_file';

const smallScreenWidth = 640.0;
const showHistoryRightWidth = 840.0;
const logoPngPath = 'assets/images/logo/logo.png';
const logoWarnPngPath = 'assets/images/logo/logo-warn.png';
const logoIcoPath = 'assets/images/logo/logo.ico';
const logoWarnIcoPath = 'assets/images/logo/logo-warn.ico';
const shizukuLogoPath = 'assets/images/logo/shizuku.png';
const rootLogoPath = 'assets/images/logo/root.png';
const emptyPngPath = 'assets/images/empty.png';
final emptyPngBytes = base64Decode(
  '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',
);

final logoImg = Image.asset(
  logoPngPath,
  width: 20,
  height: 20,
);

//设备类型图片
final Map<PlatformType, Icon> devTypeIcons = {
  PlatformType.windows: const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.android: const Icon(
    SimpleIcons.android,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.mac: const Icon(
    Icons.laptop_mac_outlined,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.linux: const Icon(
    SimpleIcons.linux,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.ios: const Icon(
    Icons.apple_outlined,
    color: Colors.grey,
    size: 48,
  ),
};

//截屏路径关键字（Android）
final List<String> screenshotKeywords = [
  'screenshot',
  'screen_shot',
  'screen-shot',
  'screen shot',
  'screencapture',
  'screen_capture',
  'screen-capture',
  'screen capture',
  'screencap',
  'screen_cap',
  'screen-cap',
  'screen cap',
  'screenshots',
];
