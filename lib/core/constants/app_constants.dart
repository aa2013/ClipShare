
import 'package:clipshare/shared/constants/assets.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
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
