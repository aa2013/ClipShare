import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/handlers/sync/script_module_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/rule_sync_handler.dart';
import 'package:clipshare/app/modules/rules_module/rules_page.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/base/multi_drawer.dart';
import 'package:clipshare/app/widgets/base/my_navigation_rail.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/handlers/sync/app_info_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/history_source_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/history_top_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/tag_sync_handler.dart';
import 'package:clipshare/app/listeners/multi_selection_pop_scope_disable_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/clean_data_module/clean_data_controller.dart';
import 'package:clipshare/app/modules/debug_module/debug_page.dart';
import 'package:clipshare/app/modules/device_module/device_page.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/history_module/history_page.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_page.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/app_update_info_util.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:zip_flutter/zip_flutter.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

final _noScreenshot = NoScreenshot.instance;

class HomeController extends GetxController with WidgetsBindingObserver, ScreenOpenedObserver {
  String get tag => "HomeController";
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final settingsController = Get.find<SettingsController>();
  final storageService = Get.find<StorageService>();
  final androidChannelService = Get.find<AndroidChannelService>();

  //多选监听
  final Set<MultiSelectionPopScopeDisableListener> _multiSelectionPopScopeDisableListeners = {};

  //region 在小屏下首页中排除的导航栏和页面
  static const _rulesNavItemKey = Key('rules');
  static const _rulesPageKey = Key('rules');
  static const _notShowNavItemKeys = [_rulesNavItemKey];
  static const _notShowPageKeys = [_rulesPageKey];

  //endregion

  //region 属性
  static const defaultDrawerWidth = 400.0;
  final _drawerWidth = defaultDrawerWidth.obs;

  double get drawerWidth => _drawerWidth.value;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  final _index = 0.obs;

  set index(value) {
    if (_index.value != value) {
      showingHistorySearch.value = false;
    }
    _index.value = value;
  }

  int get index {
    var i = _index.value;
    if (i >= pages.length) {
      i = _index.value = pages.length - 1;
    }
    return i;
  }

  final _screenWidth = Get.width.obs;

  set screenWidth(value) {
    _screenWidth.value = value;
  }

  double get screenWidth => _screenWidth.value;

  bool get isBigScreen => screenWidth >= Constants.smallScreenWidth;
  final _pages = List<GetView>.from([
    HistoryPage(),
    DevicePage(),
    SyncFilePage(),
    RulesPage(key: _rulesPageKey),
    SettingsPage(),
  ]).obs;

  List<GetView> get pages => isBigScreen ? _leftBarPages : _bottomNavPages;

  GetxController get currentPageController => pages[index].controller;

  bool get isHistoryPage => pages[index] is HistoryPage;

  //所有的导航栏
  final _navBarItems = <BottomNavigationBarItem>[].obs;

  //小屏下底部导航菜单
  List<GetView> get _bottomNavPages => _pages.where((item) => !_notShowPageKeys.contains(item.key)).toList();

  List<BottomNavigationBarItem> get bottomNavBarItems => _navBarItems.where((item) => !_notShowNavItemKeys.contains(item.key)).toList();

  //大屏下侧边导航菜单
  List<GetView> get _leftBarPages => _pages.toList();

  List<MyNavigationItem> get leftBarItems => _navBarItems
      .map(
        (item) => MyNavigationItem(
          icon: item.icon,
          label: Text(item.label ?? ""),
          tooltip: item.label!,
        ),
      )
      .toList();

  var leftMenuExtend = true.obs;

  //region 同步处理器
  late TagSyncHandler _tagSyncer;
  late HistoryTopSyncHandler _historyTopSyncer;
  late HistorySourceSyncHandler _historySourceSyncer;
  late AppInfoSyncHandler _appInfoSyncer;
  late RuleSyncHandler _ruleSyncer;
  late ScriptModuleSyncHandler _scriptModuleSyncer;

  //endregion

  //网络监听器
  late StreamSubscription _networkListener;
  DateTime? pausedTime;

  //软件logo
  final logoImg = Image.asset(
    Constants.logoPngPath,
    width: 24,
    height: 24,
  );

  //是否拖拽中
  final dragging = false.obs;

  //展示待发送文件的遮罩页面
  final showPendingItemsDetail = false.obs;

  //是否分词中，用于控制是否展示分词遮罩
  final isSegmenting = false.obs;

  //需要分词的文本
  final segmentText = ''.obs;

  //是否是文件同步页面
  bool get isSyncFilePage => _pages[index] is SyncFilePage;

  final showingHistorySearch = false.obs;

  final drawer = MultiDrawerController();

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    initNavBarItems();
    assert(() {
      _pages.add(DebugPage());
      return true;
    }());
  }

  @override
  void onReady() {
    super.onReady();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    ScreenOpenedListener.inst.register(this);
    _initCommon();
    if (Platform.isAndroid) {
      _initAndroid();
    }
    if (PlatformExt.isDesktop) {
      clipboardManager.startListening();
    } else {
      clipboardManager
          .startListening(
            env: appConfig.workingMode,
            way: appConfig.clipboardListeningWay,
            notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
          )
          .then((started) {
            settingsController.checkAndroidEnvPermission();
          });
    }
    AppUpdateInfoUtil.showUpdateInfo(debounce: true);
    appConfig.setSystemUIOverlayAutoStyle();
  }

  @override
  Future<void> onScreenOpened() async {
    //此处应该发送socket通知同步剪贴板到本机
    sktService.reqMissingData();
    if (appConfig.authenticating.value || !appConfig.useAuthentication) return;
    gotoAuthenticationPage(
      TranslationKey.authenticationPageBackendTimeoutVerificationTitle.tr,
    );
  }

  @override
  void onClose() {
    ScreenOpenedListener.inst.remove(this);
    _tagSyncer.dispose();
    _historyTopSyncer.dispose();
    _historySourceSyncer.dispose();
    _appInfoSyncer.dispose();
    _ruleSyncer.dispose();
    _scriptModuleSyncer.dispose();
    _networkListener.cancel();
    drawer.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Log.debug(tag, "AppLifecycleState $state");
    switch (state) {
      case AppLifecycleState.resumed:
        AppUpdateInfoUtil.showUpdateInfo(debounce: true);
        if (!appConfig.useAuthentication || appConfig.authenticating.value || pausedTime == null) {
          return;
        }
        var authDurationSeconds = appConfig.appRevalidateDuration;
        var now = DateTime.now();
        // 计算秒数差异
        int offsetMinutes = now.difference(pausedTime!).inMinutes;
        Log.debug(
          tag,
          "offsetMinutes $offsetMinutes,authDurationSeconds $authDurationSeconds",
        );
        if (offsetMinutes < authDurationSeconds) {
          return;
        }
        gotoAuthenticationPage(
          TranslationKey.authenticationPageBackendTimeoutVerificationTitle.tr,
        );
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (pausedTime != null) {
          Log.debug(tag, "$state skip!!");
          break;
        }
        if (appConfig.authenticating.value) {
          pausedTime = null;
        } else {
          pausedTime = DateTime.now();
        }
        break;
      default:
        break;
    }
  }

  //endregion

  //region 初始化
  /// 初始化通用行为
  void _initCommon() async {
    //初始化socket
    sktService.init();
    storageService.restart();
    _networkListener = Connectivity().onConnectivityChanged.listen(_onNetworkChanged);
    _tagSyncer = TagSyncHandler();
    _historyTopSyncer = HistoryTopSyncHandler();
    _historySourceSyncer = HistorySourceSyncHandler();
    _appInfoSyncer = AppInfoSyncHandler();
    _ruleSyncer = RuleSyncHandler();
    _scriptModuleSyncer = ScriptModuleSyncHandler();
    //进入主页面后标记为不是第一次进入
    if (appConfig.firstStartup) {
      appConfig.setNotFirstStartup();
    }
    initAutoCleanDataTimer();
    if (appConfig.useAuthentication) {
      if (!PlatformExt.isDesktop || !appConfig.startMini) {
        gotoAuthenticationPage(TranslationKey.authenticationPageTitle.tr, lock: true);
      }
    }
  }

  void initAutoCleanDataTimer() {
    final cleanDataCtl = Get.find<CleanDataController>();
    cleanDataCtl.initAutoClean();
  }

  ///初始化 initAndroid 平台
  Future<void> _initAndroid() async {
    //检查权限
    var permHandlers = [
      FloatPermHandler(),
      if (appConfig.workingMode == EnvironmentType.shizuku && !appConfig.ignoreShizuku) ShizukuPermHandler(),
      NotifyPermHandler(),
    ];
    for (var handler in permHandlers) {
      handler.hasPermission().then((v) {
        if (!v) {
          handler.request();
        }
      });
    }
    androidChannelService.showOnRecentTasks(appConfig.showOnRecentTasks);
    if (appConfig.useAuthentication) {
      _noScreenshot.screenshotOff();
    }
    try {
      await Directory(appConfig.documentsPath).create(recursive: true);
    } catch (err, stack) {
      Global.showTipsDialog(context: Get.context!, text: "$err,$stack");
    }
  }

  ///初始化导航栏
  void initNavBarItems() {
    const size = 20.0;
    final items = [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.history,
          size: size,
        ),
        label: TranslationKey.historyRecord.tr,
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.devices_rounded,
          size: size,
        ),
        label: TranslationKey.myDevice.tr,
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.sync_alt_outlined,
          size: size,
        ),
        label: TranslationKey.fileTransfer.tr,
      ),
      BottomNavigationBarItem(
        key: _rulesNavItemKey,
        icon: Icon(
          Icons.code_outlined,
          size: size,
        ),
        label: TranslationKey.rulesManagement.tr,
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.settings,
          size: size,
        ),
        label: TranslationKey.appSettings.tr,
      ),
    ];
    assert(() {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(
            Icons.bug_report_outlined,
            size: size,
          ),
          label: "Debug",
        ),
      );
      return true;
    }());
    _navBarItems.value = items;
  }

  //endregion

  //region 页面跳转相关

  ///重置抽屉宽度
  void resetDrawerWidth([double? width]) {
    _drawerWidth.value = width ?? defaultDrawerWidth;
  }

  ///跳转验证页面
  Future? gotoAuthenticationPage(
    localizedReason, {
    bool lock = true,
  }) {
    appConfig.authenticating.value = true;
    return Get.toNamed(
      Routes.AUTHENTICATION,
      arguments: {
        "lock": lock,
        "localizedReason": localizedReason,
      },
    );
  }

  ///显示历史页面并应用过滤条件
  void showHistoryWithFilter(String? devId, String? tagName) {
    final historyController = Get.find<HistoryController>();
    historyController.loadFromExternalParams(devId, tagName);
    final i = _navBarItems.indexWhere((element) => (element.icon as Icon).icon == Icons.history);
    if (i >= 0) {
      _index.value = i;
    }
  }

  ///导航至文件同步页面
  void gotoFileSyncPage() {
    if (isBigScreen) {
      var i = _navBarItems.indexWhere(
        (element) => (element.icon as Icon).icon == Icons.sync_alt_outlined,
      );
      _index.value = i;
      _pages[i] = SyncFilePage();
    } else {
      Get.toNamed(Routes.SYNC_FILE);
    }
  }

  //endregion 页面跳转

  //region 多选返回监听
  void notifyMultiSelectionPopScopeDisable() {
    for (var listener in _multiSelectionPopScopeDisableListeners) {
      listener.onPopScopeDisableMultiSelection();
    }
  }

  void registerMultiSelectionPopScopeDisableListener(
    MultiSelectionPopScopeDisableListener listener,
  ) {
    _multiSelectionPopScopeDisableListeners.add(listener);
  }

  void removeMultiSelectionPopScopeDisableListener(
    MultiSelectionPopScopeDisableListener listener,
  ) {
    _multiSelectionPopScopeDisableListeners.remove(listener);
  }

  //endregion

  Timer? _networkChangedTimer;
  Future<void> _onNetworkChanged(ConnectivityResult result) async {
    _networkChangedTimer?.cancel();
    _networkChangedTimer = Timer(1500.ms, (){
      Log.debug(tag, "网络变化 -> ${result.name}");
      final lastNetwork = appConfig.currentNetWorkType.value;
      //网络变化前的状态，非无网络状态,断开中转服务连接
      if (lastNetwork != ConnectivityResult.none) {
        sktService.disConnectAllConnections();
        storageService.disconnectWs();
      }
      appConfig.currentNetWorkType.value = result;
      //网络变化后的处理，重新连接/设备发现
      if (result != ConnectivityResult.none) {
        storageService.reconnectWs();
        storageService.uploadSyncFailedData();
        sktService.restartDiscoveryDevices();
      }
    });
  }

  //region drawer 打开和关闭

  void pushDrawer({
    required Widget widget,
    double? width,
    BeforeDrawerClosed? beforeClosed,
  }) {
    if (width != null) {
      _drawerWidth.value = width;
    }
    drawer.push(widget, beforeClosed);
  }

  Future<void> popDrawer() {
    return drawer.popWithAnimation();
  }

  //endregion

  ///显示分词信息
  Future<void> showSegmentWordsView(BuildContext context, String content) async {
    final enabled = await appConfig.checkJiebaSegment();
    if (!enabled) {
      final dirPath = await appConfig.getJiebaSegmentFileDirPath();
      DialogController? dialog;
      dialog = await Global.showTipsDialog(
        context: context,
        text: TranslationKey.notFoundJiebaFiles.trParams({"dirPath": dirPath}),
        okText: TranslationKey.installJiebaDictFile.tr,
        neutralText: TranslationKey.downloadFromGithub.tr,
        onOk: () async {
          const downloadUrl = Constants.jiebaDownloadUrl;
          var downPath = "";
          const fileName = "jieba.zip";
          if (Platform.isAndroid) {
            downPath = "${Constants.androidDownloadPath}/ClipShare/$fileName";
          } else {
            downPath = "${appConfig.documentsPath}/temp/$fileName";
          }
          await dialog?.close();
          Global.showDownloadingDialog(
            context: Get.context!,
            url: downloadUrl,
            filePath: downPath,
            content: const Text(fileName),
            onFinished: (success) async {
              try {
                if (success) {
                  final extraTo = await appConfig.getJiebaSegmentFileDirPath();
                  await ZipFile.openAndExtractAsync(downPath, extraTo);
                  Global.showSnackBarSuc(text: TranslationKey.jiebaFileInstallSuccess.tr, context: Get.context);
                  await File(downPath).delete();
                } else {
                  Global.showSnackBarErr(text: TranslationKey.downloadFailed.tr, context: Get.context);
                }
              } catch (err, stack) {
                Global.showTipsDialog(context: Get.context!, text: "error $err,$stack");
              }
            },
            onError: (error, stack) {
              Global.showTipsDialog(context: Get.context!, text: "error $error,$stack");
            },
          );
        },
        onNeutral: () {
          Constants.jiebaGithubUrl.askOpenUrl();
        },
        showCancel: true,
        showNeutral: true,
      );
      return;
    }
    final home = Get.find<HomeController>();
    home.isSegmenting.value = true;
    home.segmentText.value = content;
  }
}
