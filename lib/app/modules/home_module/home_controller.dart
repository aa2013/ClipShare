import 'dart:async';
import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/handlers/sync/app_info_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/history_source_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/history_top_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/rules_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/tag_sync_handler.dart';
import 'package:clipshare/app/listeners/multi_selection_pop_scope_disable_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/clean_data_module/clean_data_controller.dart';
import 'package:clipshare/app/modules/debug_module/debug_page.dart';
import 'package:clipshare/app/modules/device_module/device_page.dart';
import 'package:clipshare/app/modules/history_module/history_page.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart' as search_module;
import 'package:clipshare/app/modules/search_module/search_page.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_page.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/clipboard_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/app_update_info_util.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:no_screenshot/no_screenshot.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

final _noScreenshot = NoScreenshot.instance;

class HomeController extends GetxController with WidgetsBindingObserver, ScreenOpenedObserver {
  final appConfig = Get.find<ConfigService>();
  final settingsController = Get.find<SettingsController>();

  final androidChannelService = Get.find<AndroidChannelService>();
  final Set<MultiSelectionPopScopeDisableListener> _multiSelectionPopScopeDisableListeners = {};

  //region 属性
  final _drawer = Rx<Widget>(const SizedBox.shrink());

  Widget? get drawer => _drawer.value;
  final _drawerWidth = Rx<double?>(null);

  double? get drawerWidth => _drawerWidth.value;
  final _onEndDrawerClosed = Rx<Function?>(null);

  Function? get onEndDrawerClosed => _onEndDrawerClosed.value;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  final _index = 0.obs;

  set index(value) => _index.value = value;

  int get index => _index.value;

  final _pages = List<GetView>.from([
    HistoryPage(),
    DevicePage(),
    SyncFilePage(),
    SettingsPage(),
  ]).obs;

  GetxController get currentPageController => pages[index].controller;

  RxList<GetView> get pages => _pages;

  final _navBarItems = <BottomNavigationBarItem>[].obs;

  RxList<BottomNavigationBarItem> get navBarItems => _navBarItems;

  List<NavigationRailDestination> get leftBarItems => _navBarItems
      .map(
        (item) => NavigationRailDestination(
          icon: item.icon,
          label: Text(item.label ?? ""),
        ),
      )
      .toList();

  var leftMenuExtend = true.obs;
  late TagSyncHandler _tagSyncer;
  late HistoryTopSyncHandler _historyTopSyncer;
  late HistorySourceSyncHandler _historySourceSyncer;
  late AppInfoSyncHandler _appInfoSyncer;
  late RulesSyncHandler _rulesSyncer;
  late StreamSubscription _networkListener;
  DateTime? _lastNetworkChangeTime;
  DateTime? pausedTime;
  final logoImg = Image.asset(
    'assets/images/logo/logo.png',
    width: 24,
    height: 24,
  );

  String get tag => "HomeController";

  final _screenWidth = Get.width.obs;

  set screenWidth(value) {
    _screenWidth.value = value;
    _initSearchPageShow();
  }

  double get screenWidth => _screenWidth.value;

  bool get isBigScreen => screenWidth >= Constants.smallScreenWidth;

  final sktService = Get.find<SocketService>();
  final dragging = false.obs;
  final showPendingItemsDetail = false.obs;

  bool get isSyncFilePage => _pages[index] is SyncFilePage;

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
    _initSearchPageShow();
    if (Platform.isWindows || Platform.isLinux) {
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
    AppUpdateInfoUtil.showUpdateInfo(true);
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
    _rulesSyncer.dispose();
    _networkListener.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Log.debug(tag, "AppLifecycleState $state");
    switch (state) {
      case AppLifecycleState.resumed:
        AppUpdateInfoUtil.showUpdateInfo(true);
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
    _networkListener = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      _lastNetworkChangeTime = DateTime.now();
      Log.debug(tag, "网络变化 -> ${result.name}");
      if (appConfig.currentNetWorkType.value != ConnectivityResult.none) {
        sktService.disConnectAllConnections();
      }
      appConfig.currentNetWorkType.value = result;
      if (result != ConnectivityResult.none) {
        var delayMs = 0;
        if (_lastNetworkChangeTime != null) {
          var now = DateTime.now();
          final diffMs = (now.difference(_lastNetworkChangeTime!).inMilliseconds).abs();
          if (diffMs < 1000) {
            Log.debug(tag, "Delay execution due to less than 1000ms(act ${diffMs}ms) since the last network change");
            delayMs = 1000;
          }
        }
        await Future.delayed(Duration(milliseconds: delayMs), sktService.restartDiscoveryDevices);
      }
    });
    _tagSyncer = TagSyncHandler();
    _historyTopSyncer = HistoryTopSyncHandler();
    _historySourceSyncer = HistorySourceSyncHandler();
    _appInfoSyncer = AppInfoSyncHandler();
    _rulesSyncer = RulesSyncHandler();
    //进入主页面后标记为不是第一次进入
    if (appConfig.firstStartup) {
      appConfig.setNotFirstStartup();
    }
    initAutoCleanDataTimer();
    if (appConfig.useAuthentication) {
      gotoAuthenticationPage(TranslationKey.authenticationPageTitle.tr, lock: true);
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
    //如果开启短信同步且有短信权限则启动短信监听
    if (appConfig.enableSmsSync && await PermissionHelper.testAndroidReadSms()) {
      androidChannelService.startSmsListen();
    }
    androidChannelService.showOnRecentTasks(appConfig.showOnRecentTasks);
    if (appConfig.useAuthentication) {
      _noScreenshot.screenshotOff();
    }
  }

  ///初始化导航栏
  void initNavBarItems() {
    final items = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.history),
        label: TranslationKey.historyRecord.tr,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.devices_rounded),
        label: TranslationKey.myDevice.tr,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.sync_alt_outlined),
        label: TranslationKey.fileTransfer.tr,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        label: TranslationKey.appSettings.tr,
      ),
    ];
    assert(() {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bug_report_outlined),
          label: "Debug",
        ),
      );
      return true;
    }());
    _navBarItems.value = items;
  }

  void _initSearchPageShow() {
    var searchNavBarIdx = _navBarItems.indexWhere((element) => (element.icon as Icon).icon == Icons.search);
    final searchPageIdx = _pages.indexWhere((p) => p is SearchPage);
    var settingNavBarIdx = _navBarItems.indexWhere((e) => (e.icon as Icon).icon == Icons.settings);
    var hasSearchPage = searchPageIdx != -1;
    var hasSearchNavBar = searchNavBarIdx != -1;
    if (isBigScreen) {
      //大屏幕
      //如果没有搜索页则加入
      if (!hasSearchPage) {
        _pages.insert(
          settingNavBarIdx,
          SearchPage(),
        );
      }
      if (!hasSearchNavBar) {
        _navBarItems.insert(
          settingNavBarIdx,
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: TranslationKey.bottomNavigationSearchHistoryBarItemLabel.tr,
          ),
        );
      }
    } else {
      //如果有搜索页则移除
      if (hasSearchPage) {
        _pages.removeAt(searchPageIdx);
      }
      //如果有搜索导航栏且则移除
      if (hasSearchNavBar) {
        _navBarItems.removeAt(searchNavBarIdx);
      }
    }
  }

  //endregion

  //region 页面跳转相关

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

  ///导航至搜索页面
  void gotoSearchPage(String? devId, String? tagName) {
    final searchController = Get.find<search_module.SearchController>();
    searchController.loadFromExternalParams(devId, tagName);
    if (isBigScreen) {
      var i = _navBarItems.indexWhere((element) => (element.icon as Icon).icon == Icons.search);
      _index.value = i;
      pages[i] = SearchPage();
    } else {
      Get.toNamed(Routes.SEARCH);
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

  ///region drawer 打开和关闭
  void openEndDrawer({
    required Widget drawer,
    double? width = 400,
    Function? onDrawerClosed,
  }) {
    closeEndDrawer();
    _drawer.value = drawer;
    _drawerWidth.value = width;
    _onEndDrawerClosed.value = onDrawerClosed;
    homeScaffoldKey.currentState?.openEndDrawer();
  }

  void closeEndDrawer() {
    homeScaffoldKey.currentState?.closeEndDrawer();
    _onEndDrawerClosed.value = null;
  }

  ///endregion
}
