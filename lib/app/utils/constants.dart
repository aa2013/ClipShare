import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/widgets/radio_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        },
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
  static final defaultHistoryWindowKeys = "${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.altLeft.usbHidUsage};${PhysicalKeyboardKey.keyH.usbHidUsage}";

  //文件同步快捷键（Ctrl + Shift + C）
  static final defaultSyncFileHotKeys = "${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyC.usbHidUsage}";

  //显示主窗体快捷键（Ctrl + Shift + S）
  static final defaultShowMainWindowHotKeys = "${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyS.usbHidUsage}";

  //退出程序快捷键（Ctrl + Shift + Q）
  static final defaultExitAppHotKeys = "${Platform.isMacOS ? PhysicalKeyboardKey.metaLeft.usbHidUsage : PhysicalKeyboardKey.controlLeft.usbHidUsage},${PhysicalKeyboardKey.shiftLeft.usbHidUsage};${PhysicalKeyboardKey.keyQ.usbHidUsage}";

  static const androidRootStoragePath = "/storage/emulated/0";
  static const androidDownloadPath = "$androidRootStoragePath/Download";
  static const androidPicturesPath = "$androidRootStoragePath/Pictures";
  static const androidDocumentsPath = "$androidRootStoragePath/Documents";
  static const androidDataPath = "/storage/emulated/0/Android/data";

  static Future<String> get documentsPath async {
    String dir;
    if (Platform.isAndroid) {
      dir = "$androidDocumentsPath/ClipShare/";
    } else {
      dir = "${(await getApplicationDocumentsDirectory()).path}/ClipShare/";
    }
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
  static const androidReadFileEventChannel = "top.coclyun.clipshare/read_file";

  static const smallScreenWidth = 640.0;
  static const showHistoryRightWidth = 840.0;
  static const logoPngPath = "assets/images/logo/logo.png";
  static const logoIcoPath = "assets/images/logo/logo.ico";
  static const shizukuLogoPath = "assets/images/logo/shizuku.png";
  static const rootLogoPath = "assets/images/logo/root.png";
  static const emptyPngPath = 'assets/images/empty.png';
  static final emptyPngBytes = base64Decode(
    "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",
  );

  static List<RadioData<int>> get authBackEndTimeSelections => [
    RadioData(value: 0, label: TranslationKey.immediately.tr),
    RadioData(value: 1, label: "1 ${TranslationKey.minute.tr}"),
    RadioData(value: 2, label: "2 ${TranslationKey.minute.tr}"),
    RadioData(value: 5, label: "5 ${TranslationKey.minute.tr}"),
    RadioData(value: 10, label: "10 ${TranslationKey.minute.tr}"),
    RadioData(value: 30, label: "30 ${TranslationKey.minute.tr}"),
  ];

  static List<RadioData> get languageSelections {
    return [
        RadioData(value: 'zh_CN', label: "简体中文"),
        RadioData(value: 'en_US', label: "English"),
      ]
      ..sort((a, b) => a.label.compareTo(b.label))
      ..insert(0, RadioData(value: 'auto', label: TranslationKey.auto.tr));
  }

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

  static const windowsDirSeparate = "\\";
  static const unixDirSeparate = "/";

  static const httpUrlRegex = r'^(http|https)://[^\s]+$';
  static const wsUrlRegex = r'^(ws|wss)://[^\s]+$';

  static String get dirSeparate => Platform.isWindows ? windowsDirSeparate : unixDirSeparate;

  static const defaultNotificationServer = "ws://notify.clipshare.coclyun.top";

  static const defaultWsPingIntervalTime = 30;

  static const jiebaDownloadUrl = 'https://download.clipshare.coclyun.top/others/jieba.zip';

  static const jiebaGithubUrl = 'https://github.com/w568w/jieba_flutter/tree/master/assets';
}
