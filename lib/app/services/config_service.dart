import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/devicce_id_generate_way.dart';
import 'package:clipshare/app/data/enums/forward_way.dart';
import 'package:clipshare/app/data/enums/config_key.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/data/models/white_black_rule.dart';
import 'package:clipshare/app/handlers/storage/s3_client.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clean_data_config.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/snowflake.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistent_device_id/persistent_device_id.dart';
import 'package:share_handler/share_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

class ConfigService extends GetxService {
  final dbService = Get.find<DbService>();
  final configDao = Get.find<DbService>().configDao;
  final tag = "ConfigService";

  //region 属性

  //region 常量
  //通用通道
  final commonChannel = const MethodChannel(Constants.channelCommon);

  //剪贴板通道
  final clipChannel = const MethodChannel(Constants.channelClip);

  //Android平台通道
  final androidChannel = const MethodChannel(Constants.channelAndroid);
  final prime1 = CryptoUtil.getPrime();
  final prime2 = CryptoUtil.getPrime();

  // final bgColor = const Color.fromARGB(255, 238, 238, 238);
  WindowController? historyWindow;
  WindowController? onlineDevicesWindow;
  final mainWindowId = 0;

  StreamSubscription<SharedMedia>? shareHandlerStream;

  //当前设备id
  late final DevInfo devInfo;
  late final Device device;
  late final Snowflake snowflake;
  late final AppVersion version;
  late final double osVersion;
  final minVersion = const AppVersion("1.0.0-beta", "3");

  //路径
  late final String documentPath;
  late final String androidPrivatePicturesPath;
  late final String cachePath;

  //文件默认存储路径
  Future<String> get defaultFileStorePath async {
    var path = "${Directory(Platform.resolvedExecutable).parent.path}/files";
    if (Platform.isAndroid) {
      path = "${Constants.androidDownloadPath}/${Constants.appName}";
    } else if (Platform.isWindows) {
      //Windows 下如果没有权限写入默认位置则修改为document文件夹下
      if (!FileUtil.testWriteable(path)) {
        path = "${await Constants.documentsPath}/files";
      }
    } else if (Platform.isMacOS) {
      var dir = await getApplicationDocumentsDirectory();
      path = dir.path + "/${Constants.appName}/files".normalizePath;
    }
    var dir = Directory(path);
    try {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (err, stack) {
      Log.error(tag, err, stack);
    }
    return Directory(path).normalizePath;
  }

  //日志路径
  late final String logsDirPath;

  //endregion

  //region 响应式

  //region 应用内配置

  //当前是否是深色模式
  bool get currentIsDarkMode {
    if (appTheme == ThemeMode.system) {
      return Get.isDarkMode;
    }
    return appTheme == ThemeMode.dark;
  }

  //当前网络环境
  final currentNetWorkType = ConnectivityResult.none.obs;

  bool get isSmallScreen => Get.width <= Constants.smallScreenWidth;

  final _innerCopy = false.obs;

  bool get innerCopy => _innerCopy.value;

  set innerCopy(bool value) {
    _innerCopy.value = value;
    Future.delayed(300.ms, () {
      _innerCopy.value = false;
    });
  }

  final selectingWorkingMode = false.obs;
  final _isMultiSelectionMode = false.obs;

  bool get isEnableMultiSelectionMode => _isMultiSelectionMode.value;
  GetxController? _selectionModeController;
  final _multiSelectionText = TranslationKey.multipleChoiceOperationAppBarTitle.tr.obs;

  bool isMultiSelectionMode(GetxController controller) {
    if (controller == _selectionModeController && _isMultiSelectionMode.value) {
      return true;
    }
    return false;
  }

  String get multiSelectionText => _multiSelectionText.value;

  set multiSelectionText(val) => _multiSelectionText.value = val;

  void enableMultiSelectionMode({
    String? selectionTips,
    required GetxController controller,
  }) {
    _isMultiSelectionMode.value = true;
    _selectionModeController = controller;
    if (selectionTips != null) {
      _multiSelectionText.value = selectionTips;
    }
  }

  void disableMultiSelectionMode([bool clear = true]) {
    _isMultiSelectionMode.value = false;
    if (clear) {
      _selectionModeController = null;
    }
  }

  final authenticating = false.obs;

  final _userId = 0.obs;

  set userId(value) => _userId.value = value;

  int get userId => _userId.value;
  final deviceDiscoveryStatus = Rx<String?>(null);

  //本机是否启用 webdav 中转
  bool get enableWebdav => forwardWay == ForwardWay.webdav;

  //本机是否启用 对象存储 中转
  bool get enableS3 => forwardWay == ForwardWay.s3;

  //本机是否启用 存储 进行中转
  bool get enableStorageSync => enableWebdav || enableS3;

  //endregion

  //region 存储于数据库的配置
  //端口
  late final RxInt _port;

  int get port => _port.value;

  //本地名称（设备名称）
  late final RxString _localName;

  String get localName => _localName.value;

  //开机启动
  final RxBool _launchAtStartup = false.obs;

  bool get launchAtStartup => _launchAtStartup.value;

  //启动最小化
  late final RxBool _startMini;

  bool get startMini => _startMini.value;

  //允许自动发现
  late final RxBool _allowDiscover;

  bool get allowDiscover => _allowDiscover.value;

  //显示历史悬浮窗
  late final RxBool _showHistoryFloat;

  bool get showHistoryFloat => _showHistoryFloat.value;

  //锁定悬浮窗位置
  late final RxBool _lockHistoryFloatLoc;

  bool get lockHistoryFloatLoc => _lockHistoryFloatLoc.value;

  //是否第一次打开软件
  late final RxBool _firstStartup;

  bool get firstStartup => _firstStartup.value;

  //记录的上次窗口大小，格式为：width x height。默认值为：1000x650
  late final RxString _windowSize;

  String get windowSize => _windowSize.value;

  //是否记住窗体大小
  late final RxBool _rememberWindowSize;

  bool get rememberWindowSize => _rememberWindowSize.value;

  //是否记录历史记录弹窗位置
  late final _recordHistoryDialogPosition = false.obs;

  bool get recordHistoryDialogPosition => _recordHistoryDialogPosition.value;

  //历史记录弹窗位置
  final _historyDialogPosition = "".obs;

  Offset get historyDialogPosition {
    if (_historyDialogPosition.value == "") {
      return Offset.zero;
    }
    try {
      final [dx, dy] = _historyDialogPosition.split("x");
      return Offset(dx.toDouble(), dy.toDouble());
    } catch (_) {
      return Offset.zero;
    }
  }

  //显示在最近任务中（Android）
  final RxBool _showOnRecentTasks = true.obs;

  bool get showOnRecentTasks => _showOnRecentTasks.value;

  //息屏一段时间后自动断连
  final RxBool _autoCloseConnAfterScreenOff = true.obs;

  bool get autoCloseConnAfterScreenOff => _autoCloseConnAfterScreenOff.value;

  //在一行中显示多项
  final RxBool _showMoreItemsInRow = false.obs;

  bool get showMoreItemsInRow => _showMoreItemsInRow.value;

  //桌面端使用同一快捷键关闭弹窗
  final RxBool _closeOnSameHotKey = false.obs;

  bool get closeOnSameHotKey => _closeOnSameHotKey.value;

  //主题
  late final RxString _appTheme;

  final _cleanDataConfig = Rx<CleanDataConfig?>(null);

  CleanDataConfig? get cleanDataConfig => _cleanDataConfig.value;

  ThemeMode get appTheme {
    final value = _appTheme.value;
    for (var mode in ThemeMode.values) {
      if (mode.name.toLowerCase() == value.toLowerCase()) {
        return mode;
      }
    }
    return ThemeMode.system;
  }

  //语言
  final RxString _language = 'auto'.obs;

  String get language => _language.value;

  //标签规则
  final _tagRules = Rx<String?>(null);

  String get tagRules => _tagRules.value ?? Constants.defaultTagRules;

  //短信规则
  final _smsRules = Rx<String?>(null);

  String get smsRules => _smsRules.value ?? Constants.defaultSmsRules;

  //启用日志记录
  late final RxBool _enableLogsRecord;

  bool get enableLogsRecord => _enableLogsRecord.value;

  //启用崩溃日志自动上报
  late final RxBool _enableAutoUploadCrashLogs;

  bool get enableAutoUploadCrashLogs => _enableAutoUploadCrashLogs.value;

  //历史记录弹窗快捷键
  late final RxString _historyWindowHotKeys;

  String get historyWindowHotKeys => _historyWindowHotKeys.value;

  //文件同步快捷键
  late final RxString _syncFileHotKeys;

  String get syncFileHotKeys => _syncFileHotKeys.value;

  //显示主窗体快捷键
  late final RxString _showMainWindowHotKeys;

  String get showMainWindowHotKeys => _showMainWindowHotKeys.value;

  //退出程序快捷键
  late final RxString _exitAppHotKeys;

  String get exitAppHotKeys => _exitAppHotKeys.value;

  //心跳间隔时长
  late final RxInt _heartbeatInterval;

  int get heartbeatInterval => _heartbeatInterval.value;

  //文件存储路径
  late final RxString _fileStorePath;

  String get rootStorePath => _fileStorePath.value;

  String get fileStorePath => "$rootStorePath/files".normalizePath;

  String get screenShotStorePath => "$rootStorePath/Screenshots".normalizePath;

  //保存至相册
  late final RxBool _saveToPictures;

  bool get saveToPictures => _saveToPictures.value;

  //忽略Shizuku权限
  late final RxBool _ignoreShizuku;

  bool get ignoreShizuku => _ignoreShizuku.value;

  //使用安全认证
  late final RxBool _useAuthentication;

  bool get useAuthentication => _useAuthentication.value;

  //app密码重新验证时长
  late final RxInt _appRevalidateDuration;

  int get appRevalidateDuration => _appRevalidateDuration.value;

  //app密码
  late final Rx<String?> _appPassword;

  String? get appPassword => _appPassword.value;

  //是否启用短信同步
  late final RxBool _enableSmsSync;

  bool get enableSmsSync => _enableSmsSync.value;

  //是否启用中转服务
  late final RxBool _enableForward;

  bool get enableForward => _enableForward.value;

  //图片同步后自动复制
  late final RxBool _autoCopyImageAfterSync;

  bool get autoCopyImageAfterSync => _autoCopyImageAfterSync.value;

  //截屏后自动复制（Android）
  late final RxBool _autoCopyImageAfterScreenShot;

  bool get autoCopyImageAfterScreenShot => _autoCopyImageAfterScreenShot.value;

  //中转服务器地址
  final Rx<ForwardServerConfig?> _forwardServer = Rx<ForwardServerConfig?>(null);

  ForwardServerConfig? get forwardServer => _forwardServer.value;

  //选择的工作模式（Android）
  late final Rx<EnvironmentType?> _workingMode;

  EnvironmentType? get workingMode => _workingMode.value;

  //仅中转模式（Debug）
  late final RxBool _onlyForwardMode;

  bool get onlyForwardMode {
    if (kReleaseMode) {
      return false;
    }
    return _onlyForwardMode.value;
  }

  //忽略更新的版本
  final Rx<String?> _ignoreUpdateVersion = Rx<String?>(null);

  String? get ignoreUpdateVersion => _ignoreUpdateVersion.value;

  //剪贴板监听方式
  final Rx<ClipboardListeningWay?> _clipboardListeningWay = Rx<ClipboardListeningWay?>(null);

  ClipboardListeningWay get clipboardListeningWay => _clipboardListeningWay.value ?? ClipboardListeningWay.hiddenApi;

  //屏幕亮起时发现设备
  final _enableAutoSyncOnScreenOpened = true.obs;

  bool get enableAutoSyncOnScreenOpened => _enableAutoSyncOnScreenOpened.value;

  //剪贴板来源记录
  final _sourceRecord = false.obs;

  bool get sourceRecord => _sourceRecord.value;

  //剪贴板来源记录（通过dumpsys）
  final _sourceRecordViaDumpsys = false.obs;

  bool get sourceRecordViaDumpsys => _sourceRecordViaDumpsys.value && sourceRecord;

  //设备断开连接后通知
  final _notifyOnDevDisconn = true.obs;

  bool get notifyOnDevDisconn => _notifyOnDevDisconn.value;

  //设备连接后通知
  final _notifyOnDevConn = true.obs;

  bool get notifyOnDevConn => _notifyOnDevConn.value;

  //自动同步缺失的数据
  final _autoSyncMissingData = true.obs;

  bool get autoSyncMissingData => _autoSyncMissingData.value;

  //黑名单功能
  final _enableContentBlackList = false.obs;

  bool get enableContentBlackList => _enableContentBlackList.value;

  //黑名单列表
  final _contentBlackList = <FilterRule>[].obs;

  List<FilterRule> get contentBlackList => _contentBlackList.value;

  //启用通知记录
  final _enableRecordNotification = false.obs;

  bool get enableRecordNotification => _enableRecordNotification.value;

  //通知黑白名单模式
  final _currentNotificationWhiteBlackMode = WhiteBlackMode.black.obs;

  WhiteBlackMode get currentNotificationWhiteBlackMode => _currentNotificationWhiteBlackMode.value;

  //通知黑名单列表
  final _notificationBlackList = <FilterRule>[].obs;

  List<FilterRule> get notificationBlackList => _notificationBlackList.value;

  //通知白名单列表
  final _notificationWhiteList = <FilterRule>[].obs;

  List<FilterRule> get notificationWhiteList => _notificationWhiteList.value;

  //显示移动设备的通知
  final _enableShowMobileNotification = false.obs;

  bool get enableShowMobileNotification => _enableShowMobileNotification.value;

  //webdav配置
  final _webdavConfig = Rx<WebDavConfig?>(null);

  //webdav配置
  WebDavConfig? get webDavConfig => _webdavConfig.value;

  //s3配置
  final _s3Config = Rx<S3Config?>(null);

  //s3配置
  S3Config? get s3Config => _s3Config.value;

  //中转方式
  final _forwardWay = ForwardWay.webdav.obs;

  //使用的中转方式
  ForwardWay get forwardWay => _forwardWay.value;

  //中转方式
  final _notificationServer = Rx<String>(Constants.defaultNotificationServer);

  String get notificationServer => _notificationServer.value;

  //移动设备id生成方式
  final _mobileDevIdGenerateWay = Rx<DeviceIdGenerateWay>(DeviceIdGenerateWay.unknown);

  DeviceIdGenerateWay get mobileDevIdGenerateWay => _mobileDevIdGenerateWay.value;

  //endregion

  //endregion

  //endregion

  //region 初始化

  Future<ConfigService> init() async {
    await loadConfigs();
    await initDeviceInfo();
    snowflake = Snowflake(device.guid.hashCode);
    await initPath();
    return this;
  }

  ///加载配置信息
  Future<void> loadConfigs() async {
    var cfg = dbService.configDao;
    _port = (await cfg.getConfigByKey(ConfigKey.port, Constants.port)).obs;
    _localName = (await cfg.getConfigByKey(ConfigKey.localName, '')).obs;
    _startMini = (await cfg.getConfigByKey(ConfigKey.startMini, false)).obs;
    _allowDiscover = (await cfg.getConfigByKey(ConfigKey.allowDiscover, true)).obs;
    _showHistoryFloat = (await cfg.getConfigByKey(ConfigKey.showHistoryFloat, false)).obs;
    _firstStartup = (await cfg.getConfigByKey(ConfigKey.firstStartup, true)).obs;
    _rememberWindowSize = (await cfg.getConfigByKey(ConfigKey.rememberWindowSize, false)).obs;
    _windowSize = (await cfg.getConfigByKey(
      ConfigKey.windowSize,
      Constants.defaultWindowSize,
      convert: (value) {
        if (rememberWindowSize) {
          return value;
        }
        return Constants.defaultWindowSize;
      },
    )).obs;
    _lockHistoryFloatLoc = (await cfg.getConfigByKey(ConfigKey.lockHistoryFloatLoc, true)).obs;
    _enableLogsRecord = (await cfg.getConfigByKey(ConfigKey.enableLogsRecord, false)).obs;
    _enableAutoUploadCrashLogs = (await cfg.getConfigByKey(ConfigKey.enableAutoUploadCrashLogs, false)).obs;
    _tagRules.value = (await cfg.getConfigByKey<String?>(ConfigKey.tagRules, null));
    _smsRules.value = (await cfg.getConfigByKey<String?>(ConfigKey.smsRules, null));
    _historyWindowHotKeys = (await cfg.getConfigByKey(ConfigKey.historyWindowHotKeys, Constants.defaultHistoryWindowKeys)).obs;
    _syncFileHotKeys = (await cfg.getConfigByKey(ConfigKey.syncFileHotKeys, Constants.defaultSyncFileHotKeys)).obs;
    _showMainWindowHotKeys = (await cfg.getConfigByKey(ConfigKey.showMainWindowHotKeys, "")).obs;
    _exitAppHotKeys = (await cfg.getConfigByKey(ConfigKey.exitAppHotKeys, "")).obs;
    _heartbeatInterval = (await cfg.getConfigByKey(ConfigKey.heartbeatInterval, Constants.heartbeatInterval)).obs;
    _fileStorePath = (await cfg.getConfigByKey(
      ConfigKey.fileStorePath,
      await defaultFileStorePath,
      convert: (value) => Directory(fileStorePath).absolute.normalizePath,
    )).obs;
    _saveToPictures = (await cfg.getConfigByKey(ConfigKey.saveToPictures, false)).obs;
    _ignoreShizuku = (await cfg.getConfigByKey(ConfigKey.ignoreShizuku, false)).obs;
    _useAuthentication = (await cfg.getConfigByKey(ConfigKey.useAuthentication, false)).obs;
    _appRevalidateDuration = (await cfg.getConfigByKey(ConfigKey.appRevalidateDuration, 0)).obs;
    _appPassword = (await cfg.getConfigByKey<String?>(ConfigKey.appPassword, null)).obs;
    _enableSmsSync = (await cfg.getConfigByKey(ConfigKey.enableSmsSync, false)).obs;
    _enableForward = (await cfg.getConfigByKey(ConfigKey.enableForward, false)).obs;
    _notificationServer.value = await cfg.getConfigByKey<String>(ConfigKey.notificationServer, Constants.defaultNotificationServer);
    _forwardWay.value = await cfg.getConfigByKey<ForwardWay>(
      ConfigKey.forwardWay,
      ForwardWay.none,
      convert: (s) {
        try {
          return ForwardWay.values.byName(s);
        } catch (err, stack) {
          return ForwardWay.none;
        }
      },
    );
    _forwardServer.value = (await cfg.getConfigByKey<ForwardServerConfig?>(
      ConfigKey.forwardServer,
      null,
      convert: (value) {
        if (value.startsWith("{")) {
          return ForwardServerConfig.fromJson(jsonDecode(value));
        } else {
          final [host, port] = value.split(":");
          return ForwardServerConfig(host: host, port: port.toInt());
        }
      },
    ));
    _webdavConfig.value = await cfg.getConfigByKey<WebDavConfig?>(
      ConfigKey.webdavConfig,
      null,
      convert: (s) {
        try {
          return WebDavConfig.fromJson(jsonDecode(s));
        } catch (err, stack) {
          return null;
        }
      },
    );
    _s3Config.value = await cfg.getConfigByKey<S3Config?>(
      ConfigKey.s3Config,
      null,
      convert: (s) {
        try {
          return S3Config.fromJson(jsonDecode(s));
        } catch (err, stack) {
          return null;
        }
      },
    );
    _workingMode = (await cfg.getConfigByKey<EnvironmentType?>(ConfigKey.workingMode, null, convert: EnvironmentType.parse)).obs;
    _onlyForwardMode = (await cfg.getConfigByKey(ConfigKey.onlyForwardMode, false)).obs;
    _appTheme = (await cfg.getConfigByKey(ConfigKey.appTheme, ThemeMode.system.name)).obs;
    changeThemeMode(appTheme);
    _autoCopyImageAfterSync = (await cfg.getConfigByKey(ConfigKey.autoCopyImageAfterSync, false)).obs;
    _autoCopyImageAfterScreenShot = (await cfg.getConfigByKey(ConfigKey.autoCopyImageAfterScreenShot, true)).obs;
    _ignoreUpdateVersion.value = (await cfg.getConfigByKey<String?>(ConfigKey.ignoreUpdateVersion, null));
    _language.value = (await cfg.getConfigByKey(ConfigKey.appLanguage, 'auto'));
    _recordHistoryDialogPosition.value = (await cfg.getConfigByKey(ConfigKey.recordHistoryDialogPosition, false));
    _historyDialogPosition.value = (await cfg.getConfigByKey(ConfigKey.historyDialogPosition, ""));
    _showOnRecentTasks.value = await cfg.getConfigByKey(ConfigKey.showOnRecentTasks, true);
    _autoCloseConnAfterScreenOff.value = (await cfg.getConfigByKey(ConfigKey.autoCloseConnAfterScreenOff, true));
    _cleanDataConfig.value = (await cfg.getConfigByKey<CleanDataConfig?>(
      ConfigKey.cleanDataConfig,
      null,
      convert: (value) {
        try {
          return CleanDataConfig.fromJson(cleanDataConfig.toString());
        } catch (err, stack) {
          debugPrint(err.toString());
          debugPrintStack(stackTrace: stack);
          return null;
        }
      },
    ));
    _showMoreItemsInRow.value = (await cfg.getConfigByKey(ConfigKey.showMoreItemsInRow, true));
    _clipboardListeningWay.value = await cfg.getConfigByKey(
      ConfigKey.clipboardListeningWay,
      ClipboardListeningWay.logs,
      convert: ClipboardListeningWay.parse,
    );
    _closeOnSameHotKey.value = (await cfg.getConfigByKey(ConfigKey.closeOnSameHotKey, false));
    _enableAutoSyncOnScreenOpened.value = (await cfg.getConfigByKey(ConfigKey.enableAutoSyncOnScreenOpened, true));
    _sourceRecord.value = (await cfg.getConfigByKey(ConfigKey.sourceRecord, PlatformExt.isDesktop));
    _sourceRecordViaDumpsys.value = (await cfg.getConfigByKey(ConfigKey.sourceRecordViaDumpsys, false));
    _notifyOnDevDisconn.value = (await cfg.getConfigByKey(ConfigKey.notifyOnDevDisconn, true));
    _notifyOnDevConn.value = (await cfg.getConfigByKey(ConfigKey.notifyOnDevConn, true));
    _autoSyncMissingData.value = (await cfg.getConfigByKey(ConfigKey.autoSyncMissingData, true));
    _enableContentBlackList.value = (await cfg.getConfigByKey(ConfigKey.enableContentBlackList, false));
    _contentBlackList.value = (await cfg.getConfigByKey(
      ConfigKey.blacklist,
      [],
      convert: (value) {
        try {
          List<Map<String, dynamic>> jsonList = (jsonDecode(value) as List<dynamic>).cast();
          return jsonList.map((item) => FilterRule.fromJson(item)).toList();
        } catch (err, stack) {
          debugPrint(err.toString());
          debugPrintStack(stackTrace: stack);
          return [];
        }
      },
    ));
    _enableRecordNotification.value = (await cfg.getConfigByKey(ConfigKey.enableRecordNotification, false));
    _enableShowMobileNotification.value = (await cfg.getConfigByKey(ConfigKey.enableShowMobileNotification, false));
    final notificationBlackWhiteList = await cfg.getConfigByKey(ConfigKey.notificationBlackWhiteList, "");
    try {
      if (notificationBlackWhiteList.isNullOrEmpty) {
        _notificationWhiteList.value = [];
        _notificationBlackList.value = [];
      } else {
        final map = jsonDecode(notificationBlackWhiteList) as Map<String, dynamic>;
        _currentNotificationWhiteBlackMode.value = WhiteBlackMode.values.byName(map["mode"].toString());
        _notificationBlackList.value = (map["blacklist"]! as List<dynamic>).map((item) => FilterRule.fromJson(item)).toList();
        _notificationWhiteList.value = (map["whitelist"]! as List<dynamic>).map((item) => FilterRule.fromJson(item)).toList();
      }
    } catch (err, stack) {
      debugPrint(err.toString());
      debugPrintStack(stackTrace: stack);
      _notificationWhiteList.value = [];
      _notificationBlackList.value = [];
    }
    _webdavConfig.value = (await cfg.getConfigByKey(
      ConfigKey.webdavConfig,
      null,
      convert: (value) {
        final json = jsonDecode(value) as Map<dynamic, dynamic>;
        return WebDavConfig.fromJson(json.cast());
      },
    ));
    _mobileDevIdGenerateWay.value = await cfg.getConfigByKey(
      ConfigKey.mobileDevIdGenerateWay,
      DeviceIdGenerateWay.unknown,
      convert: DeviceIdGenerateWay.parse,
    );
  }

  ///初始化路径信息
  Future<void> initPath() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
      documentPath = (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))![0].path;
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/pictures
      androidPrivatePicturesPath = (await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      ))![0].path;
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
      cachePath = (await getExternalCacheDirectories())![0].path;
    } else {
      documentPath = (await getApplicationDocumentsDirectory()).path;
      cachePath = (await getApplicationCacheDirectory()).path;
    }
    await initLogsDirPath();
  }

  ///初始化日志路径
  Future<void> initLogsDirPath() async {
    var path = "$cachePath/logs";
    if (Platform.isWindows) {
      //Windows 下如果没有权限写入默认位置则修改为document文件夹下
      path = Directory(
        "${Directory(Platform.resolvedExecutable).parent.path}/logs",
      ).absolute.normalizePath;
      if (!FileUtil.testWriteable(path)) {
        path = "${await Constants.documentsPath}/logs";
      }
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    path = Directory(path).normalizePath;
    logsDirPath = path;
  }

  ///初始化设备信息
  Future<void> initDeviceInfo() async {
    //读取版本信息
    var pkgInfo = await PackageInfo.fromPlatform();
    version = AppVersion(pkgInfo.version, pkgInfo.buildNumber);
    //读取设备id信息
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var guid = "";
    var name = "";
    var type = "";
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      final useAndroidId = [DeviceIdGenerateWay.unknown, DeviceIdGenerateWay.androidId].contains(_mobileDevIdGenerateWay.value);
      if (useAndroidId && !firstStartup) {
        //使用 Android id
        guid = CryptoUtil.toMD5(androidInfo.id);
        await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
      } else {
        try {
          //Android id 有可能会重复，如果是首次启动，使用 PersistentDeviceId 生成 id，理论上卸载/重启后都不会变化
          await PersistentDeviceId.getDeviceId().then((id) async {
            if (id != null) {
              guid = CryptoUtil.toMD5(id);
              await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.persistentDeviceId);
            } else {
              //获取失败，仍然使用Android id兜底
              guid = CryptoUtil.toMD5(androidInfo.id);
              await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
            }
          });
        } catch (err, stack) {
          guid = CryptoUtil.toMD5(androidInfo.id);
          await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
          debugPrint("$err,$stack");
        }
      }
      name = androidInfo.model;
      type = "Android";
      var release = androidInfo.version.release;
      osVersion = RegExp(r"\d+").firstMatch(release)!.group(0)!.toDouble();
    } else if (Platform.isWindows) {
      var windowsInfo = await deviceInfo.windowsInfo;
      guid = CryptoUtil.toMD5(windowsInfo.deviceId);
      name = windowsInfo.computerName;
      type = "Windows";
    } else if (Platform.isLinux) {
      var linuxInfo = await deviceInfo.linuxInfo;
      guid = CryptoUtil.toMD5(linuxInfo.id);
      name = linuxInfo.name;
      type = "Linux";
    } else if (Platform.isMacOS) {
      var macosInfo = await deviceInfo.macOsInfo;
      guid = CryptoUtil.toMD5(macosInfo.systemGUID!);
      name = macosInfo.computerName;
      type = "Mac";
    } else {
      throw Exception("Not Support Platform");
    }

    assert(() {
      guid = "debug-$guid";
      return true;
    }());

    devInfo = DevInfo(guid, name, type);
    if (_localName.value.isNullOrEmpty) {
      _localName.value = devInfo.name;
    } else {
      devInfo.name = _localName.value;
    }
    device = Device(
      guid: guid,
      devName: name,
      customName: "本机",
      uid: 0,
      type: type,
    );
  }

  //endregion

  //region 更新存储于数据库的配置
  Future<void> setAllowDiscover(bool allowDiscover) async {
    await configDao.addOrUpdate(ConfigKey.allowDiscover, allowDiscover.toString());
    _allowDiscover.value = allowDiscover;
  }

  Future<void> setStartMini(bool startMini) async {
    await configDao.addOrUpdate(ConfigKey.startMini, startMini.toString());
    _startMini.value = startMini;
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup, [bool deleteWindowsShortcut = false]) async {
    _launchAtStartup.value = launchAtStartup;
    Log.debug(tag, "launchAtStartup $launchAtStartup, deleteWindowsShortcut $deleteWindowsShortcut");
    if (launchAtStartup && !deleteWindowsShortcut) return;
    if (Platform.isWindows) {
      final startupPaths = <String>[
        Constants.windowsStartUpPath,
      ];
      final userStartupPath = Constants.windowsUserStartUpPath;
      if (userStartupPath != null) {
        startupPaths.add(userStartupPath);
      }
      for (var startupPath in startupPaths) {
        final dir = Directory(startupPath);
        if (!dir.existsSync()) continue;
        await dir.deleteTargetFileShortcut(
          Platform.resolvedExecutable,
        );
      }
    }
  }

  Future<void> setPort(int port) async {
    await configDao.addOrUpdate(ConfigKey.port, port.toString());
    _port.value = port;
  }

  Future<void> setLocalName(String localName) async {
    await configDao.addOrUpdate(ConfigKey.localName, localName);
    devInfo.name = localName;
    _localName.value = localName;
  }

  Future<void> setShowHistoryFloat(bool showHistoryFloat) async {
    await configDao.addOrUpdate(ConfigKey.showHistoryFloat, showHistoryFloat.toString());
    _showHistoryFloat.value = showHistoryFloat;
  }

  Future<void> setLockHistoryFloatLoc(bool lockHistoryFloatLoc) async {
    await configDao.addOrUpdate(ConfigKey.lockHistoryFloatLoc, lockHistoryFloatLoc.toString());
    _lockHistoryFloatLoc.value = lockHistoryFloatLoc;
  }

  Future<void> setNotFirstStartup() async {
    await configDao.addOrUpdate(ConfigKey.firstStartup, false.toString());
    _firstStartup.value = false;
  }

  Future<void> setRememberWindowSize(bool rememberWindowSize) async {
    await configDao.addOrUpdate(ConfigKey.rememberWindowSize, rememberWindowSize.toString());
    Size size = await windowManager.getSize();
    _rememberWindowSize.value = rememberWindowSize;
    _windowSize.value = "${size.width.toInt()}x${size.height.toInt()}";
  }

  Future<void> setWindowSize(Size windowSize) async {
    var size = "${windowSize.width.toInt()}x${windowSize.height.toInt()}";
    await configDao.addOrUpdate(ConfigKey.windowSize, size);
    _windowSize.value = size;
  }

  Future<void> setRecordHistoryDialogPosition(
    bool recordHistoryDialogPosition,
  ) async {
    await configDao.addOrUpdate(ConfigKey.recordHistoryDialogPosition, recordHistoryDialogPosition.toString());
    _recordHistoryDialogPosition.value = recordHistoryDialogPosition;
  }

  Future<void> setHistoryDialogPosition(String historyDialogPosition) async {
    await configDao.addOrUpdate(ConfigKey.historyDialogPosition, historyDialogPosition);
    _historyDialogPosition.value = historyDialogPosition;
  }

  Future<void> setShowOnRecentTasks(bool showOnRecentTasks) async {
    await configDao.addOrUpdate(ConfigKey.showOnRecentTasks, showOnRecentTasks.toString());
    _showOnRecentTasks.value = showOnRecentTasks;
  }

  Future<void> setAutoCloseConnAfterScreenOff(bool autoCloseConnAfterScreenOff) async {
    await configDao.addOrUpdate(
      ConfigKey.autoCloseConnAfterScreenOff,
      autoCloseConnAfterScreenOff.toString(),
    );
    _autoCloseConnAfterScreenOff.value = autoCloseConnAfterScreenOff;
  }

  Future<void> setEnableLogsRecord(bool enableLogsRecord) async {
    await configDao.addOrUpdate(ConfigKey.enableLogsRecord, enableLogsRecord.toString());
    _enableLogsRecord.value = enableLogsRecord;
  }

  Future<void> setEnableAutoUploadCrashLogs(bool enableAutoUploadCrashLogs) async {
    await configDao.addOrUpdate(ConfigKey.enableAutoUploadCrashLogs, enableAutoUploadCrashLogs.toString());
    _enableAutoUploadCrashLogs.value = enableAutoUploadCrashLogs;
  }

  Future<void> setTagRules(String tagRules) async {
    await configDao.addOrUpdate(ConfigKey.tagRules, tagRules.toString());
    _tagRules.value = tagRules;
  }

  Future<void> setSmsRules(String smsRules) async {
    await configDao.addOrUpdate(ConfigKey.smsRules, smsRules);
    if (_smsRules.value == null) {
      _smsRules.value = smsRules;
    } else {
      _smsRules!.value = smsRules;
    }
  }

  Future<void> setHistoryWindowHotKeys(String historyWindowHotKeys) async {
    await configDao.addOrUpdate(ConfigKey.historyWindowHotKeys, historyWindowHotKeys);
    _historyWindowHotKeys.value = historyWindowHotKeys;
  }

  Future<void> setSyncFileHotKeys(String syncFileHotKeys) async {
    await configDao.addOrUpdate(ConfigKey.syncFileHotKeys, syncFileHotKeys);
    _syncFileHotKeys.value = syncFileHotKeys;
  }

  Future<void> setShowMainWindowHotKeys(String showMainWindowHotKeys) async {
    await configDao.addOrUpdate(ConfigKey.showMainWindowHotKeys, showMainWindowHotKeys);
    _showMainWindowHotKeys.value = showMainWindowHotKeys;
  }

  Future<void> setExitAppHotKeys(String exitAppHotKeys) async {
    await configDao.addOrUpdate(ConfigKey.exitAppHotKeys, exitAppHotKeys);
    _exitAppHotKeys.value = exitAppHotKeys;
  }

  Future<void> setHeartbeatInterval(String heartbeatInterval) async {
    await configDao.addOrUpdate(ConfigKey.heartbeatInterval, heartbeatInterval);
    _heartbeatInterval.value = heartbeatInterval.toInt();
  }

  Future<void> setFileStorePath(String fileStorePath) async {
    await configDao.addOrUpdate(ConfigKey.fileStorePath, fileStorePath);
    _fileStorePath.value = fileStorePath;
  }

  Future<void> setSaveToPictures(bool saveToPictures) async {
    await configDao.addOrUpdate(ConfigKey.saveToPictures, saveToPictures.toString());
    _saveToPictures.value = saveToPictures;
  }

  Future<void> setIgnoreShizuku() async {
    await configDao.addOrUpdate(ConfigKey.ignoreShizuku, true.toString());
    _ignoreShizuku.value = true;
  }

  Future<void> setUseAuthentication(bool useAuthentication) async {
    await configDao.addOrUpdate(ConfigKey.useAuthentication, useAuthentication.toString());
    _useAuthentication.value = useAuthentication;
    if (PlatformExt.isMobile) {
      if (useAuthentication) {
        _noScreenshot.screenshotOff();
      } else {
        _noScreenshot.screenshotOn();
      }
    }
  }

  Future<void> setAppRevalidateDuration(int appRevalidateDuration) async {
    await configDao.addOrUpdate(ConfigKey.appRevalidateDuration, appRevalidateDuration.toString());
    _appRevalidateDuration.value = appRevalidateDuration;
  }

  Future<void> setAppPassword(String appPassword) async {
    appPassword = CryptoUtil.toMD5(appPassword);
    await configDao.addOrUpdate(ConfigKey.appPassword, appPassword);
    _appPassword.value = appPassword;
  }

  Future<void> setEnableSmsSync(bool enableSmsSync) async {
    await configDao.addOrUpdate(ConfigKey.enableSmsSync, enableSmsSync.toString());
    _enableSmsSync.value = enableSmsSync;
  }

  Future<void> setEnableForward(bool enableForward) async {
    await configDao.addOrUpdate(ConfigKey.enableForward, enableForward.toString());
    _enableForward.value = enableForward;
  }

  Future<void> setForwardServer(ForwardServerConfig serverConfig) async {
    await configDao.addOrUpdate(ConfigKey.forwardServer, serverConfig.toString());
    _forwardServer.value = serverConfig;
  }

  Future<void> setWorkingMode(EnvironmentType workingMode) async {
    await configDao.addOrUpdate(ConfigKey.workingMode, workingMode.name);
    _workingMode.value = workingMode;
  }

  Future<void> setOnlyForwardMode(bool onlyForwardMode) async {
    await configDao.addOrUpdate(ConfigKey.onlyForwardMode, onlyForwardMode.toString());
    _onlyForwardMode.value = onlyForwardMode;
    if (!onlyForwardMode) return;
    final sktService = Get.find<SocketService>();
    return sktService.disConnectAllConnections();
  }

  Future<void> setAutoCopyImageAfterSync(bool autoCopyImageAfterSync) async {
    await configDao.addOrUpdate(
      ConfigKey.autoCopyImageAfterSync,
      autoCopyImageAfterSync.toString(),
    );
    _autoCopyImageAfterSync.value = autoCopyImageAfterSync;
  }

  Future<void> setAutoCopyImageAfterScreenShot(
    bool autoCopyImageAfterScreenShot,
  ) async {
    await configDao.addOrUpdate(
      ConfigKey.autoCopyImageAfterScreenShot,
      autoCopyImageAfterScreenShot.toString(),
    );
    _autoCopyImageAfterScreenShot.value = autoCopyImageAfterScreenShot;
  }

  Future<void> setAppTheme(
    ThemeMode appTheme,
    BuildContext context, [
    VoidCallback? onAnimationFinish,
  ]) async {
    await configDao.addOrUpdate(ConfigKey.appTheme, appTheme.name);
    _appTheme.value = appTheme.name;
    var theme = appTheme == ThemeMode.dark ? darkThemeData : lightThemeData;
    if (appTheme == ThemeMode.system) {
      theme = Get.isPlatformDarkMode ? darkThemeData : lightThemeData;
    }
    final isDarkTheme = theme == darkThemeData;
    ThemeSwitcher.of(context).changeTheme(
      theme: theme,
      isReversed: false,
      onAnimationFinish: onAnimationFinish,
    );
    if (isDarkTheme) {
      setSystemUIOverlayDarkStyle();
    } else {
      setSystemUIOverlayLightStyle();
    }
  }

  Future<void> setIgnoreUpdateVersion(String versionCode) async {
    await configDao.addOrUpdate(ConfigKey.ignoreUpdateVersion, versionCode);
    _ignoreUpdateVersion.value = versionCode;
  }

  Future<void> setAppLanguage(String language) async {
    await configDao.addOrUpdate(ConfigKey.appLanguage, language);
    _language.value = language;
    updateLanguage();
    final homeController = Get.find<HomeController>();
    homeController.initNavBarItems();
    final settingController = Get.find<SettingsController>();
    settingController.checkAndroidEnvPermission();
  }

  Future<void> setCleanDataConfig(CleanDataConfig cleanDataConfig) async {
    await configDao.addOrUpdate(ConfigKey.cleanDataConfig, cleanDataConfig.toString());
    _cleanDataConfig.value = cleanDataConfig;
  }

  Future<void> setShowMoreItemsInRow(bool showMoreItemsInRow) async {
    await configDao.addOrUpdate(ConfigKey.showMoreItemsInRow, showMoreItemsInRow.toString());
    _showMoreItemsInRow.value = showMoreItemsInRow;
  }

  Future<void> setClipboardListeningWay(ClipboardListeningWay way) async {
    await configDao.addOrUpdate(ConfigKey.clipboardListeningWay, way.name.toString());
    _clipboardListeningWay.value = way;
  }

  Future<void> setCloseOnSameHotKey(bool closeOnSameHotKey) async {
    await configDao.addOrUpdate(ConfigKey.closeOnSameHotKey, closeOnSameHotKey.toString());
    _closeOnSameHotKey.value = closeOnSameHotKey;
  }

  Future<void> setEnableAutoSyncOnScreenOpened(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.enableAutoSyncOnScreenOpened, enable.toString());
    _enableAutoSyncOnScreenOpened.value = enable;
  }

  Future<void> setEnableSourceRecord(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.sourceRecord, enable.toString());
    _sourceRecord.value = enable;
  }

  Future<void> setEnableSourceRecordViaDumpsys(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.sourceRecordViaDumpsys, enable.toString());
    _sourceRecordViaDumpsys.value = enable;
  }

  Future<void> setNotifyOnDevDisconn(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.notifyOnDevDisconn, enable.toString());
    _notifyOnDevDisconn.value = enable;
  }

  Future<void> setNotifyOnDevConn(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.notifyOnDevConn, enable.toString());
    _notifyOnDevConn.value = enable;
  }

  Future<void> setAutoSyncMissingData(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.autoSyncMissingData, enable.toString());
    _autoSyncMissingData.value = enable;
  }

  Future<void> setEnableContentBlackList(bool enable) async {
    await configDao.addOrUpdate(ConfigKey.enableContentBlackList, enable.toString());
    _enableContentBlackList.value = enable;
  }

  ///更新内容黑名单数据
  Future<void> setContentBlacklist(List<FilterRule> rules) async {
    await configDao.addOrUpdate(ConfigKey.blacklist, jsonEncode(rules));
    _contentBlackList.value = rules;
  }

  ///更新通知黑白名单数据
  Future<void> setNotificationBlackWhiteList(WhiteBlackMode mode, List<FilterRule> blacklist, List<FilterRule> whitelist) async {
    await configDao.addOrUpdate(
      ConfigKey.notificationBlackWhiteList,
      jsonEncode({
        "mode": mode.name,
        "blacklist": blacklist,
        "whitelist": whitelist,
      }),
    );
    _currentNotificationWhiteBlackMode.value = mode;
    _notificationBlackList.value = blacklist;
    _notificationWhiteList.value = whitelist;
  }

  ///启用通知历史记录
  Future<void> setEnableRecordNotification(bool enabled) async {
    await configDao.addOrUpdate(ConfigKey.enableRecordNotification, enabled.toString());
    _enableRecordNotification.value = enabled;
  }

  ///显示移动设备的通知
  Future<void> setEnableShowMobileNotification(bool enabled) async {
    await configDao.addOrUpdate(ConfigKey.enableShowMobileNotification, enabled.toString());
    _enableShowMobileNotification.value = enabled;
  }

  ///保存 webdav 配置
  Future<void> setWebDavConfig(WebDavConfig config) async {
    await configDao.addOrUpdate(ConfigKey.webdavConfig, jsonEncode(config));
    _webdavConfig.value = config;
  }

  ///保存 s3 配置
  Future<void> setS3Config(S3Config config) async {
    await configDao.addOrUpdate(ConfigKey.s3Config, jsonEncode(config));
    _s3Config.value = config;
  }

  ///保存 中转方式 配置
  Future<void> setForwardWay(ForwardWay way) async {
    await configDao.addOrUpdate(ConfigKey.forwardWay, way.name);
    _forwardWay.value = way;
  }

  ///保存 通知服务地址 配置
  Future<void> setNotificationServer(String address) async {
    await configDao.addOrUpdate(ConfigKey.notificationServer, address);
    _notificationServer.value = address;
  }

  ///设置移动端设备id生成方式
  Future<void> setMobileDeviceIdGenerateWay(DeviceIdGenerateWay way) async {
    await configDao.addOrUpdate(ConfigKey.mobileDevIdGenerateWay, way.name);
    _mobileDevIdGenerateWay.value = way;
  }

  //endregion

  //region 其他方法

  ///将底部导航栏设置为深色
  void setSystemUIOverlayDarkStyle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
  }

  ///将底部导航栏设置为浅色
  void setSystemUIOverlayLightStyle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: lightBackgroundColor,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });
  }

  ///根据当前主题设置底部导航栏样式
  void setSystemUIOverlayAutoStyle() {
    if (currentIsDarkMode) {
      setSystemUIOverlayDarkStyle();
    } else {
      setSystemUIOverlayLightStyle();
    }
  }

  ///修改主题模式
  void changeThemeMode(ThemeMode theme) {
    Get.changeThemeMode(theme);
    setSystemUIOverlayAutoStyle();
  }

  ///更新语言选项
  void updateLanguage() {
    if (language == "auto") {
      Get.updateLocale(Get.deviceLocale ?? Constants.defaultLocale);
    } else {
      final codes = language.split('_');
      Get.updateLocale(Locale(codes[0], codes.length == 1 ? null : codes[1]));
    }
  }

  ///判断是否命中内容黑名单
  FilterRuleMatchResult matchesContentBlacklist(HistoryContentType type, String content, ClipboardSource? source) {
    if (!enableContentBlackList) {
      return FilterRuleMatchResult.notMatched;
    }
    // 遍历所有黑名单规则
    for (final rule in contentBlackList) {
      // 跳过未启用的规则
      if (!rule.enable) continue;
      if (rule.matched(type, content, source)) {
        return FilterRuleMatchResult.matched(rule);
      }
    }

    // 没有命中任何黑名单规则
    return FilterRuleMatchResult.notMatched;
  }

  ///判断是否命中通知黑白名单规则
  FilterRuleMatchResult matchesNotificationRuleList(String content, String pkgName) {
    //未启用
    if (!enableRecordNotification) {
      return FilterRuleMatchResult.notMatched;
    }
    try {
      final json = jsonDecode(content);
      final title = json["title"];
      final detail = json["content"];
      content = "$title\n$detail";
    } catch (err, stack) {
      Log.error(tag, "matchesNotificationRuleList error: $err,$stack");
    }
    final ruleList = currentNotificationWhiteBlackMode == WhiteBlackMode.black ? notificationBlackList : notificationWhiteList;
    final source = ClipboardSource(id: pkgName, name: "", time: null, iconB64: "");
    for (var rule in ruleList) {
      // 跳过未启用的规则
      if (!rule.enable) continue;
      if (rule.matched(HistoryContentType.notification, content, source)) {
        return FilterRuleMatchResult.matched(rule);
      }
    }

    //未命中
    return FilterRuleMatchResult.notMatched;
  }

  //endregion
}

DataSender get dataSender {
  return Get.find<SocketService>();
}
