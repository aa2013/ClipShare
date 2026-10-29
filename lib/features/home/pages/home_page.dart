import 'dart:async';
import 'dart:math';

import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/file/file_transfer_provider.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/features/auth/providers/app_lock_provider.dart';
import 'package:clipshare/features/debug/pages/debug_page.dart';
import 'package:clipshare/features/device/pages/device_page.dart';
import 'package:clipshare/features/file_transfer/pages/file_transfer_page.dart';
import 'package:clipshare/features/file_transfer/providers/send_compose_provider.dart';
import 'package:clipshare/features/file_transfer/utils/pending_file_resolver.dart';
import 'package:clipshare/features/file_transfer/widgets/send_files_overlay.dart';
import 'package:clipshare/features/history/pages/history_page.dart';
import 'package:clipshare/features/home/pages/home_compact_page.dart';
import 'package:clipshare/features/home/pages/home_wide_page.dart';
import 'package:clipshare/features/home/providers/drawer_provider.dart';
import 'package:clipshare/features/home/providers/home_page_index_provider.dart';
import 'package:clipshare/features/home/providers/navigation_provider.dart';
import 'package:clipshare/features/rules/pages/rules_page.dart';
import 'package:clipshare/features/settings/pages/settings.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/keyboard_shortcut.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/blur_background.dart';
import 'package:clipshare/shared/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomePage> {
  static const rulesPageKey = Key('rules-page');
  static const notShowCompactPageKeys = [rulesPageKey];
  static const navIconSize = 20.0;

  ///文件传输页在 pages 中的固定位置
  static const fileTransferPageIndex = 2;

  late final List<Widget> pages;

  @override
  void initState() {
    pages = [
      const HistoryPage(),
      const DevicePage(),
      const FileTransferPage(),
      const RulesPage(key: rulesPageKey),
      const SettingsPage(),
    ];
    assert(() {
      pages.add(const DebugPage());
      return true;
    }());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoveryNotifier = ref.read(discoveryProvider.notifier);
      discoveryNotifier.restartDiscoveryDevices();
      // 应用锁：实例化以注册生命周期/亮屏重验监听并同步防截屏状态，随后按配置触发启动锁
      final appLock = ref.read(appLockProvider.notifier);
      unawaited(appLock.maybeLockOnStartup());
    });
    //唯一在线设备时自动选中
    ref.listenManual(deviceProvider, (prev, next) {
      final devices = next.value?.onlineAndPairedList ?? const [];
      if (devices.length == 1) {
        final compose = ref.read(sendComposeProvider.notifier);
        compose.selectDevice(devices.first.guid);
      }
    });
    super.initState();
  }

  ///根据统一导航数据构建宽屏导航菜单。
  List<MyNavigationItem> buildWideNavItems(List<HomeNavigationItemData> items) {
    return items
        .map(
          (item) => MyNavigationItem(
            icon: Icon(
              item.icon,
              size: navIconSize,
            ),
            label: Text(item.label),
            tooltip: item.label,
          ),
        )
        .toList();
  }

  ///根据统一导航数据构建窄屏导航菜单。
  List<BottomNavigationBarItem> buildCompactNavItems(List<HomeNavigationItemData> items) {
    return items
        .where((item) => item.showInCompact)
        .map(
          (item) => BottomNavigationBarItem(
            icon: Icon(
              item.icon,
              size: navIconSize,
            ),
            label: item.label,
            tooltip: item.label,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = ref.watch(homeNavigationItemsProvider);
    final compose = ref.watch(sendComposeProvider);
    final composeNotifier = ref.read(sendComposeProvider.notifier);
    final pageIndex = ref.watch(homePageIndexProvider);
    final deviceState = ref.watch(deviceProvider).value;
    final onlineDevices = deviceState?.onlineAndPairedList ?? const [];
    List<Widget> showPages;
    Widget content;
    if (context.isCompactScreen) {
      showPages = pages.where((page) => !notShowCompactPageKeys.contains(page.key)).toList();
      content = HomeCompactPage(
        pages: showPages,
        navItems: buildCompactNavItems(navItems),
      );
    } else {
      showPages = pages;
      content = HomeWidePage(
        navItems: buildWideNavItems(navItems),
        pages: showPages,
      );
    }
    return CustomKeyboardListener(
      shortcuts: [
        KeyboardShortcut(
          physicalKeys: {PhysicalKeyboardKey.escape},
          onTrigger: handleEscapeShortcut,
        ),
      ],
      child: PopScope(
        canPop: !compose.overlayVisible,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            composeNotifier.closeOverlay();
          }
        },
        child: DropTarget(
          onDragDone: (detail) => _handleHomeDrop(detail.files),
          child: Stack(
            children: [
              content,
              if (compose.overlayVisible)
                Positioned.fill(
                  child: BlurBackground(
                    borderRadius: BorderRadius.circular(12),
                    child: SafeArea(
                      child: SendFilesOverlay(
                        devices: onlineDevices,
                        selectedDevIds: compose.selectedDevIds,
                        onToggleDevice: (dev) => composeNotifier.toggleDevice(dev.guid),
                        files: compose.files,
                        onRemoveFile: (file) => composeNotifier.removeFile(file),
                        onAddFiles: _pickFilesForCompose,
                        onClearAll: () => composeNotifier.clearFiles(),
                      ),
                    ),
                  ),
                ),
              Visibility(
                visible: compose.overlayVisible || (pageIndex == fileTransferPageIndex && compose.files.isNotEmpty),
                child: Positioned(
                  right: 30,
                  bottom: 30,
                  child: Row(
                    children: [
                      Visibility(
                        visible: compose.overlayVisible && compose.files.isNotEmpty,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: FloatingActionButton(
                            tooltip: TranslationKey.sendFiles.tr,
                            onPressed: _sendPendingFiles,
                            child: Transform.rotate(
                              angle: -45 * (pi / 180),
                              child: const Icon(Icons.send),
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        tooltip: compose.overlayVisible
                            ? '${TranslationKey.close.tr}${context.isCompactScreen ? '' : '(ESC)'}'
                            : TranslationKey.viewPendingFiles.tr,
                        onPressed: () {
                          if (compose.overlayVisible) {
                            composeNotifier.closeOverlay();
                          } else {
                            composeNotifier.openOverlay();
                          }
                        },
                        child: Icon(compose.overlayVisible ? Icons.close : Icons.file_open_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理页面级 Esc 快捷键：优先关闭发送遮罩，其次关闭抽屉。
  void handleEscapeShortcut() {
    final composeNotifier = ref.read(sendComposeProvider.notifier);
    if (ref.read(sendComposeProvider).overlayVisible) {
      composeNotifier.closeOverlay();
      return;
    }
    final drawer = ref.read(drawerProvider).controller;
    if (!drawer.isEmpty) {
      drawer.popWithAnimation();
      return;
    }
    //todo
    // if (appConfig.isMultiSelectionMode(currentPageController)) {
    //   appConfig.disableMultiSelectionMode(true);
    //   notifyMultiSelectionPopScopeDisable();
    // }
  }

  /// 整窗拖入：解析文件入待发列表，跳转文件传输页并打开遮罩
  Future<void> _handleHomeDrop(List<DropItem> items) async {
    final result = await resolvePendingFiles(items);
    if (!mounted) {
      return;
    }
    if (result.failedCount > 0) {
      snackbar.warn(context, TranslationKey.failedToLoad.tr);
    }
    if (result.files.isEmpty) {
      return;
    }
    final compose = ref.read(sendComposeProvider.notifier);
    compose.addFiles(result.files);
    final indexNotifier = ref.read(homePageIndexProvider.notifier);
    indexNotifier.set(fileTransferPageIndex);
    compose.openOverlay();
  }

  /// 遮罩内添加文件：解析后入待发列表
  Future<void> _pickFilesForCompose() async {
    final picked = await FileUtil.pickFiles();
    final items = picked.where((f) => f.path != null).map((f) => DropItemFile(f.path!)).toList();
    final result = await resolvePendingFiles(items);
    if (!mounted) {
      return;
    }
    if (result.failedCount > 0) {
      snackbar.warn(context, TranslationKey.failedToLoad.tr);
    }
    final compose = ref.read(sendComposeProvider.notifier);
    compose.addFiles(result.files);
  }

  /// 发送全部待发文件到选中设备，成功后清空待发列表并关闭遮罩
  Future<void> _sendPendingFiles() async {
    final composeState = ref.read(sendComposeProvider);
    final pendingFiles = composeState.files;
    if (pendingFiles.isEmpty) {
      return;
    }
    if (composeState.selectedDevIds.isEmpty) {
      await dialogManager.tips(context, text: TranslationKey.pleaseSelectDevices.tr);
      return;
    }
    final deviceState = ref.read(deviceProvider).requireValue;
    final devices = deviceState.onlineAndPairedList
        .where((dev) => composeState.selectedDevIds.contains(dev.guid))
        .map(BaseDeviceInfo.fromDevice)
        .toList();
    final expandedFiles = await expandPendingFiles(pendingFiles);
    final board = ref.read(fileTransferProvider.notifier);
    for (final dev in devices) {
      await board.sendFiles(dev, expandedFiles);
    }
    if (!mounted) {
      return;
    }
    snackbar.success(context, TranslationKey.startSendFileToast.tr);
    final compose = ref.read(sendComposeProvider.notifier);
    compose.clearFiles();
    compose.clearDevices();
    compose.closeOverlay();
  }
}
