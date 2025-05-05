import 'dart:async';
import 'dart:io';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clean_data_config.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/snowflake.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:window_manager/window_manager.dart';

class ConfigService extends GetxService {
  final dbService = Get.find<DbService>();

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
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return Directory(path).normalizePath;
  }

  //日志路径
  late final String logsDirPath;

  //endregion

  //region 响应式

  //region 应用内配置

  //当前网络环境
  final currentNetWorkType = ConnectivityResult.none.obs;

  bool get isSmallScreen => Get.width <= Constants.smallScreenWidth;
  final isHistorySyncing = false.obs;

  final _innerCopy = false.obs;

  bool get innerCopy => _innerCopy.value;

  set innerCopy(bool value) {
    _innerCopy.value = value;
    Future.delayed(const Duration(milliseconds: 300), () {
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
  RxString? _tagRules;

  String get tagRules => _tagRules?.value ?? Constants.defaultTagRules;

  //短信规则
  RxString? _smsRules;

  String get smsRules => _smsRules?.value ?? Constants.defaultSmsRules;

  //启用日志记录
  late final RxBool _enableLogsRecord;

  bool get enableLogsRecord => _enableLogsRecord.value;

  //历史记录弹窗快捷键
  late final RxString _historyWindowHotKeys;

  String get historyWindowHotKeys => _historyWindowHotKeys.value;

  //文件同步快捷键
  late final RxString _syncFileHotKeys;

  String get syncFileHotKeys => _syncFileHotKeys.value;

  //心跳间隔时长
  late final RxInt _heartbeatInterval;

  int get heartbeatInterval => _heartbeatInterval.value;

  //文件存储路径
  late final RxString _fileStorePath;

  String get fileStorePath => _fileStorePath.value;

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

  //是否启用短信同步
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

  //endregion

  //endregion

  //endregion

  //region 初始化

  Future<ConfigService> init() async {
    await initDeviceInfo();
    snowflake = Snowflake(device.guid.hashCode);
    await loadConfigs();
    await initPath();
    return this;
  }

  ///加载配置信息
  Future<void> loadConfigs() async {
    //region 获取配置值
    var cfg = dbService.configDao;
    var port = await cfg.getConfig("port", userId);
    var localName = await cfg.getConfig("localName", userId);
    var startMini = await cfg.getConfig("startMini", userId);
    var allowDiscover = await cfg.getConfig("allowDiscover", userId);
    var showHistoryFloat = await cfg.getConfig("showHistoryFloat", userId);
    var firstStartup = await cfg.getConfig("firstStartup", userId);
    var windowSize = await cfg.getConfig("windowSize", userId);
    var rememberWindowSize = await cfg.getConfig("rememberWindowSize", userId);
    var lockHistoryFloatLoc = await cfg.getConfig("lockHistoryFloatLoc", userId);
    var enableLogsRecord = await cfg.getConfig("enableLogsRecord", userId);
    var tagRules = await cfg.getConfig("tagRules", userId);
    var smsRules = await cfg.getConfig("smsRules", userId);
    var historyWindowHotKeys = await cfg.getConfig("historyWindowHotKeys", userId);
    var syncFileHotKeys = await cfg.getConfig("syncFileHotKeys", userId);
    var heartbeatInterval = await cfg.getConfig("heartbeatInterval", userId);
    var fileStorePath = await cfg.getConfig("fileStorePath", userId);
    var saveToPictures = await cfg.getConfig("saveToPictures", userId);
    var ignoreShizuku = await cfg.getConfig("ignoreShizuku", userId);
    var useAuthentication = await cfg.getConfig("useAuthentication", userId);
    var appRevalidateDuration = await cfg.getConfig("appRevalidateDuration", userId);
    var appPassword = await cfg.getConfig("appPassword", userId);
    var enableSmsSync = await cfg.getConfig("enableSmsSync", userId);
    var enableForward = await cfg.getConfig("enableForward", userId);
    var forwardServer = await cfg.getConfig("forwardServer", userId);
    var workingMode = await cfg.getConfig("workingMode", userId) ?? "none";
    var onlyForwardMode = await cfg.getConfig("onlyForwardMode", userId);
    var appTheme = await cfg.getConfig("appTheme", userId);
    var autoCopyImageAfterSync = await cfg.getConfig("autoCopyImageAfterSync", userId);
    var autoCopyImageAfterScreenShot = await cfg.getConfig("autoCopyImageAfterScreenShot", userId);
    var ignoreUpdateVersion = await cfg.getConfig("ignoreUpdateVersion", userId);
    var appLanguage = await cfg.getConfig("appLanguage", userId);
    var recordHistoryDialogPosition = await cfg.getConfig("recordHistoryDialogPosition", userId);
    var historyDialogPosition = await cfg.getConfig("historyDialogPosition", userId);
    var showOnRecentTasks = await cfg.getConfig("showOnRecentTasks", userId);
    var autoCloseConnAfterScreenOff = await cfg.getConfig("autoCloseConnAfterScreenOff", userId);
    var cleanDataConfig = await cfg.getConfig("cleanDataConfig", userId);
    var showMoreItemsInRow = await cfg.getConfig("showMoreItemsInRow", userId);
    var clipboardListeningWay = await cfg.getConfig("clipboardListeningWay", userId);
    var fileStoreDir = Directory(fileStorePath ?? await defaultFileStorePath);
    var closeOnSameHotKey = await cfg.getConfig("closeOnSameHotKey", userId);
    //endregion

    //region 设置配置值
    _port = port?.toInt().obs ?? Constants.port.obs;
    _localName = localName.isNotNullAndEmpty ? localName!.obs : devInfo.name.obs;
    _startMini = startMini?.toBool().obs ?? false.obs;
    _allowDiscover = allowDiscover?.toBool().obs ?? true.obs;
    _showHistoryFloat = showHistoryFloat?.toBool().obs ?? false.obs;
    _firstStartup = firstStartup?.toBool().obs ?? true.obs;
    _windowSize = windowSize.isNullOrEmpty || rememberWindowSize?.toBool() != true ? Constants.defaultWindowSize.obs : windowSize!.obs;
    _rememberWindowSize = rememberWindowSize?.toBool().obs ?? false.obs;
    _lockHistoryFloatLoc = lockHistoryFloatLoc?.toBool().obs ?? true.obs;
    _enableLogsRecord = enableLogsRecord?.toBool().obs ?? false.obs;
    _recordHistoryDialogPosition.value = recordHistoryDialogPosition?.toBool() ?? false;
    _historyDialogPosition.value = historyDialogPosition ?? "";
    _showOnRecentTasks.value = showOnRecentTasks?.toBool() ?? true;
    _autoCloseConnAfterScreenOff.value = autoCloseConnAfterScreenOff?.toBool() ?? true;
    _showMoreItemsInRow.value = showMoreItemsInRow?.toBool() ?? true;
    if (tagRules != null) {
      _tagRules = tagRules.obs;
    }
    if (smsRules != null) {
      _smsRules = smsRules.obs;
    }
    _historyWindowHotKeys = historyWindowHotKeys?.obs ?? Constants.defaultHistoryWindowKeys.obs;
    _syncFileHotKeys = syncFileHotKeys?.obs ?? Constants.defaultSyncFileHotKeys.obs;
    _heartbeatInterval = heartbeatInterval?.toInt().obs ?? Constants.heartbeatInterval.obs;
    _fileStorePath = fileStoreDir.absolute.normalizePath.obs;
    _saveToPictures = saveToPictures?.toBool().obs ?? false.obs;
    _ignoreShizuku = ignoreShizuku?.toBool().obs ?? false.obs;
    _useAuthentication = useAuthentication?.toBool().obs ?? false.obs;
    _appRevalidateDuration = appRevalidateDuration?.toInt().obs ?? 0.obs;
    _appPassword = appPassword.obs;
    _enableSmsSync = enableSmsSync?.toBool().obs ?? false.obs;
    _enableForward = enableForward?.toBool().obs ?? false.obs;
    if (appLanguage != null) {
      _language.value = appLanguage.toString();
    }
    if (forwardServer != null) {
      if (forwardServer.startsWith("{")) {
        _forwardServer.value = ForwardServerConfig.fromJson(forwardServer);
      } else {
        final [host, port] = forwardServer.split(":");
        _forwardServer.value = ForwardServerConfig(host: host, port: port.toInt());
      }
    }
    devInfo.name = _localName.value;
    _workingMode = EnvironmentType.parse(workingMode).obs;
    _onlyForwardMode = onlyForwardMode?.toBool().obs ?? false.obs;
    _appTheme = appTheme?.toString().obs ?? ThemeMode.system.name.obs;
    _autoCopyImageAfterSync = autoCopyImageAfterSync?.toBool().obs ?? false.obs;
    _autoCopyImageAfterScreenShot = autoCopyImageAfterScreenShot?.toBool().obs ?? true.obs;
    _ignoreUpdateVersion.value = ignoreUpdateVersion;
    _clipboardListeningWay.value = clipboardListeningWay == null ? ClipboardListeningWay.logs : ClipboardListeningWay.parse(clipboardListeningWay);
    try {
      var cleanCfg = CleanDataConfig.fromJson(cleanDataConfig.toString());
      _cleanDataConfig.value = cleanCfg;
    } catch (err) {
      print(err);
    }
    _closeOnSameHotKey.value = closeOnSameHotKey?.toBool() ?? false;
    //endregion

    Get.changeThemeMode(this.appTheme);
  }

  ///初始化路径信息
  Future<void> initPath() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
      documentPath = (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))![0]
          .path;
      androidPrivatePicturesPath = (await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      ))![0]
          .path;
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
      dir.createSync();
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
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      var guid = CryptoUtil.toMD5(androidInfo.id);
      var name = androidInfo.model;
      var type = "Android";
      devInfo = DevInfo(guid, name, type);
      device = Device(
        guid: guid,
        devName: "本机",
        uid: 0,
        type: type,
      );
      var release = androidInfo.version.release;
      osVersion = RegExp(r"\d+").firstMatch(release)!.group(0)!.toDouble();
    } else if (Platform.isWindows) {
      var windowsInfo = await deviceInfo.windowsInfo;
      var guid = CryptoUtil.toMD5(windowsInfo.deviceId);
      var name = windowsInfo.computerName;
      var type = "Windows";
      devInfo = DevInfo(guid, name, type);
      device = Device(
        guid: guid,
        devName: "本机",
        uid: userId,
        type: type,
      );
    } else {
      throw Exception("Not Support Platform");
    }
  }

//endregion

  //region 更新存储于数据库的配置
  Future<void> _addOrUpdateDbConfig(String key, String value) async {
    var v = await dbService.configDao.getConfig(key, userId);
    var cfg = Config(key: key, value: value, uid: userId);
    if (v == null) {
      await dbService.configDao.add(cfg);
    } else {
      await dbService.configDao.updateConfig(cfg);
    }
  }

  Future<void> setAllowDiscover(bool allowDiscover) async {
    await _addOrUpdateDbConfig("allowDiscover", allowDiscover.toString());
    _allowDiscover.value = allowDiscover;
  }

  Future<void> setStartMini(bool startMini) async {
    await _addOrUpdateDbConfig("startMini", startMini.toString());
    _startMini.value = startMini;
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup) async {
    _launchAtStartup.value = launchAtStartup;
    if (launchAtStartup) return;
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
    await _addOrUpdateDbConfig("port", port.toString());
    _port.value = port;
  }

  Future<void> setLocalName(String localName) async {
    await _addOrUpdateDbConfig("localName", localName);
    devInfo.name = localName;
    _localName.value = localName;
  }

  Future<void> setShowHistoryFloat(bool showHistoryFloat) async {
    await _addOrUpdateDbConfig("showHistoryFloat", showHistoryFloat.toString());
    _showHistoryFloat.value = showHistoryFloat;
  }

  Future<void> setLockHistoryFloatLoc(bool lockHistoryFloatLoc) async {
    await _addOrUpdateDbConfig("lockHistoryFloatLoc", lockHistoryFloatLoc.toString());
    _lockHistoryFloatLoc.value = lockHistoryFloatLoc;
  }

  Future<void> setNotFirstStartup() async {
    await _addOrUpdateDbConfig("firstStartup", false.toString());
    _firstStartup.value = firstStartup;
  }

  Future<void> setRememberWindowSize(bool rememberWindowSize) async {
    await _addOrUpdateDbConfig(
      "rememberWindowSize",
      rememberWindowSize.toString(),
    );
    Size size = await windowManager.getSize();
    _rememberWindowSize.value = rememberWindowSize;
    _windowSize.value = "${size.width}x${size.height}";
  }

  Future<void> setWindowSize(Size windowSize) async {
    var size = "${windowSize.width}x${windowSize.height}";
    await _addOrUpdateDbConfig("windowSize", size);
    _windowSize.value = size;
  }

  Future<void> setRecordHistoryDialogPosition(
    bool recordHistoryDialogPosition,
  ) async {
    await _addOrUpdateDbConfig("recordHistoryDialogPosition", recordHistoryDialogPosition.toString());
    _recordHistoryDialogPosition.value = recordHistoryDialogPosition;
  }

  Future<void> setHistoryDialogPosition(String historyDialogPosition) async {
    await _addOrUpdateDbConfig("historyDialogPosition", historyDialogPosition);
    _historyDialogPosition.value = historyDialogPosition;
  }

  Future<void> setShowOnRecentTasks(bool showOnRecentTasks) async {
    await _addOrUpdateDbConfig("showOnRecentTasks", showOnRecentTasks.toString());
    _showOnRecentTasks.value = showOnRecentTasks;
  }

  Future<void> setAutoCloseConnAfterScreenOff(bool autoCloseConnAfterScreenOff) async {
    await _addOrUpdateDbConfig(
      "autoCloseConnAfterScreenOff",
      autoCloseConnAfterScreenOff.toString(),
    );
    _autoCloseConnAfterScreenOff.value = autoCloseConnAfterScreenOff;
  }

  Future<void> setEnableLogsRecord(bool enableLogsRecord) async {
    await _addOrUpdateDbConfig("enableLogsRecord", enableLogsRecord.toString());
    _enableLogsRecord.value = enableLogsRecord;
  }

  Future<void> setTagRules(String tagRules) async {
    await _addOrUpdateDbConfig("tagRules", tagRules);
    if (_tagRules == null) {
      _tagRules = tagRules.obs;
    } else {
      _tagRules!.value = tagRules;
    }
  }

  Future<void> setSmsRules(String smsRules) async {
    await _addOrUpdateDbConfig("smsRules", smsRules);
    if (_smsRules == null) {
      _smsRules = smsRules.obs;
    } else {
      _smsRules!.value = smsRules;
    }
  }

  Future<void> setHistoryWindowHotKeys(String historyWindowHotKeys) async {
    await _addOrUpdateDbConfig("historyWindowHotKeys", historyWindowHotKeys);
    _historyWindowHotKeys.value = historyWindowHotKeys;
  }

  Future<void> setSyncFileHotKeys(String syncFileHotKeys) async {
    await _addOrUpdateDbConfig("syncFileHotKeys", syncFileHotKeys);
    _syncFileHotKeys.value = syncFileHotKeys;
  }

  Future<void> setHeartbeatInterval(String heartbeatInterval) async {
    await _addOrUpdateDbConfig("heartbeatInterval", heartbeatInterval);
    _heartbeatInterval.value = heartbeatInterval.toInt();
  }

  Future<void> setFileStorePath(String fileStorePath) async {
    await _addOrUpdateDbConfig("fileStorePath", fileStorePath);
    _fileStorePath.value = fileStorePath;
  }

  Future<void> setSaveToPictures(bool saveToPictures) async {
    await _addOrUpdateDbConfig("saveToPictures", saveToPictures.toString());
    _saveToPictures.value = saveToPictures;
  }

  Future<void> setIgnoreShizuku() async {
    await _addOrUpdateDbConfig("ignoreShizuku", true.toString());
    _ignoreShizuku.value = true;
  }

  Future<void> setUseAuthentication(bool useAuthentication) async {
    await _addOrUpdateDbConfig("useAuthentication", useAuthentication.toString());
    _useAuthentication.value = useAuthentication;
  }

  Future<void> setAppRevalidateDuration(int appRevalidateDuration) async {
    await _addOrUpdateDbConfig("appRevalidateDuration", appRevalidateDuration.toString());
    _appRevalidateDuration.value = appRevalidateDuration;
  }

  Future<void> setAppPassword(String appPassword) async {
    appPassword = CryptoUtil.toMD5(appPassword);
    await _addOrUpdateDbConfig("appPassword", appPassword);
    _appPassword.value = appPassword;
  }

  Future<void> setEnableSmsSync(bool enableSmsSync) async {
    await _addOrUpdateDbConfig("enableSmsSync", enableSmsSync.toString());
    _enableSmsSync.value = enableSmsSync;
  }

  Future<void> setEnableForward(bool enableForward) async {
    await _addOrUpdateDbConfig("enableForward", enableForward.toString());
    _enableForward.value = enableForward;
  }

  Future<void> setForwardServer(ForwardServerConfig serverConfig) async {
    await _addOrUpdateDbConfig("forwardServer", serverConfig.toString());
    _forwardServer.value = serverConfig;
  }

  Future<void> setWorkingMode(EnvironmentType workingMode) async {
    await _addOrUpdateDbConfig("workingMode", workingMode.name);
    _workingMode.value = workingMode;
  }

  Future<void> setOnlyForwardMode(bool onlyForwardMode) async {
    await _addOrUpdateDbConfig("onlyForwardMode", onlyForwardMode.toString());
    _onlyForwardMode.value = onlyForwardMode;
    if (!onlyForwardMode) return;
    final sktService = Get.find<SocketService>();
    return sktService.disConnectAllConnections();
  }

  Future<void> setAutoCopyImageAfterSync(bool autoCopyImageAfterSync) async {
    await _addOrUpdateDbConfig(
      "autoCopyImageAfterSync",
      autoCopyImageAfterSync.toString(),
    );
    _autoCopyImageAfterSync.value = autoCopyImageAfterSync;
  }

  Future<void> setAutoCopyImageAfterScreenShot(
    bool autoCopyImageAfterScreenShot,
  ) async {
    await _addOrUpdateDbConfig(
      "autoCopyImageAfterScreenShot",
      autoCopyImageAfterScreenShot.toString(),
    );
    _autoCopyImageAfterScreenShot.value = autoCopyImageAfterScreenShot;
  }

  Future<void> setAppTheme(
    ThemeMode appTheme,
    BuildContext context, [
    VoidCallback? onAnimationFinish,
  ]) async {
    await _addOrUpdateDbConfig("appTheme", appTheme.name);
    _appTheme.value = appTheme.name;
    var theme = appTheme == ThemeMode.dark ? darkThemeData : lightThemeData;
    if (appTheme == ThemeMode.system) {
      print("Get.isPlatformDarkMode ${Get.isPlatformDarkMode}");
      theme = Get.isPlatformDarkMode ? darkThemeData : lightThemeData;
    }
    ThemeSwitcher.of(context).changeTheme(
      theme: theme,
      isReversed: false,
      onAnimationFinish: onAnimationFinish,
    );
  }

  Future<void> setIgnoreUpdateVersion(String versionCode) async {
    await _addOrUpdateDbConfig("ignoreUpdateVersion", versionCode);
    _ignoreUpdateVersion.value = versionCode;
  }

  Future<void> setAppLanguage(String language) async {
    await _addOrUpdateDbConfig("appLanguage", language);
    _language.value = language;
    updateLanguage();
    final homeController = Get.find<HomeController>();
    homeController.initNavBarItems();
    final settingController = Get.find<SettingsController>();
    settingController.checkPermissions();
  }

  Future<void> setCleanDataConfig(CleanDataConfig cleanDataConfig) async {
    await _addOrUpdateDbConfig("cleanDataConfig", cleanDataConfig.toString());
    _cleanDataConfig.value = cleanDataConfig;
  }

  Future<void> setShowMoreItemsInRow(bool showMoreItemsInRow) async {
    await _addOrUpdateDbConfig("showMoreItemsInRow", showMoreItemsInRow.toString());
    _showMoreItemsInRow.value = showMoreItemsInRow;
  }

  Future<void> setClipboardListeningWay(ClipboardListeningWay way) async {
    await _addOrUpdateDbConfig("clipboardListeningWay", way.name.toString());
    _clipboardListeningWay.value = way;
  }

  Future<void> setCloseOnSameHotKey(bool closeOnSameHotKey) async {
    await _addOrUpdateDbConfig("closeOnSameHotKey", closeOnSameHotKey.toString());
    _closeOnSameHotKey.value = closeOnSameHotKey;
  }

//endregion

  //region 其他方法

  void updateLanguage() {
    if (language == "auto") {
      Get.updateLocale(Get.deviceLocale ?? Constants.defaultLocale);
    } else {
      final codes = language.split('_');
      Get.updateLocale(Locale(codes[0], codes.length == 1 ? null : codes[1]));
    }
  }
//endregion
}
