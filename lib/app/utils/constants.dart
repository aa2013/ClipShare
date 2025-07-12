import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/widgets/radio_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';

class Constants {
  Constants._private();

  //socket包头部大小
  static const int packetHeaderSize = 10;

  //socket包载荷最大大小
  static const int packetMaxPayloadSize = (1 << 2 * 8) - 1;

  //组播默认端口
  static const int port = 42317;

  //app名称
  static const String appName = "ClipShare";

  //默认窗体大小
  static const String defaultWindowSize = "1000x650";

  //组播地址
  static const String multicastGroup = '224.0.0.128';

  //组播心跳时长
  static const heartbeatInterval = 30;

  //中转程序下载地址
  static const forwardDownloadUrl = "https://clipshare.coclyun.top/usages/forward.html";

  //更新信息地址
  static const appUpdateInfoUtl = "https://clipshare.coclyun.top/version-info.json";

  //默认标签规则
  static String get defaultTagRules => jsonEncode(
        {
          "version": 1,
          "data": [
            {
              "name": TranslationKey.defaultLinkTagName.tr,
              "rule": r"[a-zA-z]+://[^\s]*",
            }
          ],
        },
      );

  //默认短信规则
  static String get defaultSmsRules => jsonEncode(
        {
          "version": 0,
          "data": [],
        },
      );

  //使用说明网页
  static const usageWeb = "https://clipshare.coclyun.top/usages/android.html";

  //Github
  static const githubRepo = "https://github.com/aa2013/ClipShare";

  //QQ group
  static const qqGroup = "http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=HQGbGZ-eYPNGLiawtVRuTk21RJyh87vp&authKey=mm0grlVTMpUJriGac5qBe8X50wShxlKILoeF9K6F2%2FmOpMPv60cBxZBZKs%2BSYmFI&noverify=0&group_code=622786394";

  //ClipShare 官网
  static const clipshareSite = "https://clipshare.coclyun.top";

  //默认历史弹窗快捷键（Ctrl + Alt + H）
  static const defaultHistoryWindowKeys = "458976,458978;458763";

  //文件同步快捷键（Ctrl + Shift + C）
  static const defaultSyncFileHotKeys = "458976,458977;458758";

  static const androidRootStoragePath = "/storage/emulated/0";
  static const androidDownloadPath = "$androidRootStoragePath/Download";
  static const androidPicturesPath = "$androidRootStoragePath/Pictures";
  static const androidDataPath = "/storage/emulated/0/Android/data";

  static Future<String> get documentsPath async {
    final dir = "${(await getApplicationDocumentsDirectory()).path}/ClipShare/";
    Directory(dir).createSync(recursive: true);
    return dir;
  }

  static const windowsStartUpPath = r'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup';

  static String? get windowsUserStartUpPath {
    final username = Platform.environment['USERNAME'];
    if (username == null) return null;
    return r'C:\Users\' + username + r'\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup';
  }

  //配对时限（秒）
  static const pairingLimit = 60;
  static const channelCommon = "top.coclyun.clipshare/common";
  static const channelClip = "top.coclyun.clipshare/clip";
  static const channelAndroid = "top.coclyun.clipshare/android";

  static const smallScreenWidth = 640.0;
  static const showHistoryRightWidth = 840.0;
  static const logoPngPath = "assets/images/logo/logo.png";
  static const logoIcoPath = "assets/images/logo/logo.ico";
  static const shizukuLogoPath = "assets/images/logo/shizuku.png";
  static const rootLogoPath = "assets/images/logo/root.png";

  static List<RadioData<int>> get authBackEndTimeSelections => [
        RadioData(value: 0, label: TranslationKey.immediately.tr),
        RadioData(value: 1, label: "1 ${TranslationKey.minute.tr}"),
        RadioData(value: 2, label: "2 ${TranslationKey.minute.tr}"),
        RadioData(value: 5, label: "5 ${TranslationKey.minute.tr}"),
        RadioData(value: 10, label: "10 ${TranslationKey.minute.tr}"),
        RadioData(value: 30, label: "30 ${TranslationKey.minute.tr}"),
      ];
  static final languageSelections = [
    RadioData(value: 'zh_CN', label: "简体中文"),
    RadioData(value: 'en_US', label: "English"),
  ]
    ..sort((a, b) => a.label.compareTo(b.label))
    ..insert(0, RadioData(value: 'auto', label: "Auto"));

  static const defaultLocale = Locale("zh", "CN");
  static final supportedLocales = languageSelections.sublist(1).map((item) {
    final codes = item.value.split("_");
    return Locale(codes[0], codes.length == 1 ? null : codes[1]);
  });
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  //设备类型图片
  static final Map<String, Icon> devTypeIcons = {
    'Windows': const Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Android': const Icon(
      Icons.android_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Mac': const Icon(
      Icons.laptop_mac_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Linux': Icon(
      MdiIcons.linux,
      color: Colors.grey,
      size: 48,
    ),
    'IOS': const Icon(
      Icons.apple_outlined,
      color: Colors.grey,
      size: 48,
    ),
  };

  //按键名称映射
  static final keyNameMap = [
    {
      "key": "Divide",
      "name": "/",
    },
    {
      "key": "Multiply",
      "name": "*",
    },
    {
      "key": "Subtract",
      "name": "-",
    },
    {
      "key": "Add",
      "name": "+",
    },
    {
      "key": "Equal",
      "name": "=",
    },
    {
      "key": "Minus",
      "name": "-",
    },
  ];

  //截屏路径关键字（Android）
  static final List<String> screenshotKeywords = [
    "screenshot",
    "screen_shot",
    "screen-shot",
    "screen shot",
    "screencapture",
    "screen_capture",
    "screen-capture",
    "screen capture",
    "screencap",
    "screen_cap",
    "screen-cap",
    "screen cap",
    "screenshots",
  ];

  //包名
  static const String pkgName = "clipshare.coclyun.top";

  //Windows上使用，与项目中的 windows/packaging.exe/make_config.yaml 保持一致
  static const String appGuid = "B72665DE-3DB5-B0E9-0EF9-55CCB65D3D62";
}
