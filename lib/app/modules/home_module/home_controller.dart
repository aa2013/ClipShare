import 'dart:async';
import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/handlers/sync/history_top_syncer.dart';
import 'package:clipshare/app/handlers/sync/rules_syncer.dart';
import 'package:clipshare/app/handlers/sync/tag_syncer.dart';
import 'package:clipshare/app/listeners/multi_selection_pop_scope_disable_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/debug_module/debug_page.dart';
import 'package:clipshare/app/modules/device_module/device_page.dart';
import 'package:clipshare/app/modules/history_module/history_page.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart'
    as search_module;
import 'package:clipshare/app/modules/search_module/search_page.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_page.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HomeController extends GetxController
    with WidgetsBindingObserver
    implements ScreenOpenedObserver {
  final appConfig = Get.find<ConfigService>();
  final settingsController = Get.find<SettingsController>();

  final androidChannelService = Get.find<AndroidChannelService>();
  final Set<MultiSelectionPopScopeDisableListener>
      _multiSelectionPopScopeDisableListeners = {};

  //region 属性
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

  final _navBarItems = List<BottomNavigationBarItem>.from(const [
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: '历史记录',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.devices_rounded),
      label: '我的设备',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.sync_alt_outlined),
      label: '传输记录',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '应用设置',
    ),
  ]).obs;

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
  late TagSyncer _tagSyncer;
  late HistoryTopSyncer _historyTopSyncer;
  late RulesSyncer _rulesSyncer;
  late StreamSubscription _networkListener;
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

  bool get showLeftBar => screenWidth >= Constants.smallScreenWidth;

  final sktService = Get.find<SocketService>();

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    assert(() {
      _navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bug_report_outlined),
          label: "Debug",
        ),
      );
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
    if (Platform.isWindows) {
      clipboardManager.startListening();
    } else {
      clipboardManager
          .startListening(startEnv: appConfig.workingMode)
          .then((started) {
        settingsController.checkPermissions();
      });
    }
  }

  @override
  Future<void> onOpened() async {
    //此处应该发送socket通知同步剪贴板到本机
    sktService.reqMissingData();
    if (appConfig.authenticating.value || !appConfig.useAuthentication) return;
    gotoAuthenticationPage("超时验证");
  }

  @override
  void onClose() {
    ScreenOpenedListener.inst.remove(this);
    _tagSyncer.dispose();
    _historyTopSyncer.dispose();
    _rulesSyncer.dispose();
    _networkListener.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!appConfig.useAuthentication ||
            appConfig.authenticating.value ||
            pausedTime == null) {
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
        gotoAuthenticationPage("超时验证");
        break;
      case AppLifecycleState.paused:
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
    _networkListener = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      Log.debug(tag, "网络变化 -> ${result.name}");
      if (result != ConnectivityResult.none) {
        sktService.restartDiscoveringDevices();
      }
    });
    _tagSyncer = TagSyncer();
    _historyTopSyncer = HistoryTopSyncer();
    _rulesSyncer = RulesSyncer();
    //进入主页面后标记为不是第一次进入
    if (appConfig.firstStartup) {
      appConfig.setNotFirstStartup();
    }
  }

  ///初始化 initAndroid 平台
  Future<void> _initAndroid() async {
    //检查权限
    var permHandlers = [
      FloatPermHandler(),
      if (appConfig.workingMode == EnvironmentType.shizuku &&
          !appConfig.ignoreShizuku)
        ShizukuPermHandler(),
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
    if (appConfig.enableSmsSync &&
        await PermissionHelper.testAndroidReadSms()) {
      androidChannelService.startSmsListen();
    }
  }

  void _initSearchPageShow() {
    var i = _navBarItems
        .indexWhere((element) => (element.icon as Icon).icon == Icons.search);
    var hasSearchPage = i != -1;
    if (!hasSearchPage && showLeftBar) {
      var i = _navBarItems
          .indexWhere((e) => (e.icon as Icon).icon == Icons.settings);
      _navBarItems.insert(
        i,
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: "搜索历史",
        ),
      );
      _pages.insert(
        i,
        SearchPage(),
      );
    }
    if (hasSearchPage && !showLeftBar) {
      _pages.removeAt(i);
      _navBarItems.removeAt(i);
    }
  }

  //endregion

  //region 页面跳转相关
  //跳转验证页面
  Future? gotoAuthenticationPage(localizedReason, [bool lock = true]) {
    appConfig.authenticating.value = true;
    return Get.toNamed(
      Routes.AUTHENTICATION,
      arguments: {"lock": lock, "localizedReason": localizedReason},
    );
  }

  ///导航至搜索页面
  void gotoSearchPage(String? devId, String? tagName) {
    final searchController = Get.find<search_module.SearchController>();
    searchController.loadFromExternalParams(devId, tagName);
    if (showLeftBar) {
      var i = _navBarItems
          .indexWhere((element) => (element.icon as Icon).icon == Icons.search);
      _index.value = i;
      pages[i] = SearchPage();
    } else {
      Get.toNamed(Routes.SEARCH);
    }
  }

  ///导航至文件同步页面
  void gotoFileSyncPage() {
    if (showLeftBar) {
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
}
