import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/core/utils/consumer_wrapper.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/utils/settings_section_view_factory.dart';
import 'package:clipshare/features/settings/widgets/search/settings_empty_search_tile.dart';
import 'package:clipshare/features/settings/widgets/search/settings_search_field.dart';
import 'package:clipshare/features/settings/widgets/search/settings_search_result_tile.dart';
import 'package:clipshare/features/settings/widgets/section/settings_section_tile.dart';
import 'package:clipshare/features/settings/widgets/settings_overview_group.dart';
import 'package:clipshare/features/settings/widgets/theme_mode_selector.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsOverviewPage extends ConsumerStatefulWidget {
  final ValueChanged<SettingsSection> onSectionTap;
  final ValueChanged<SettingsSearchItem>? onSearchItemTap;
  final SettingsSection? selectedSection;
  final bool embedded;

  const SettingsOverviewPage({
    super.key,
    required this.onSectionTap,
    this.onSearchItemTap,
    this.selectedSection,
    this.embedded = false,
  });

  @override
  ConsumerState<SettingsOverviewPage> createState() => _SettingsOverviewPageState();
}

class _SettingsOverviewPageState extends ConsumerState<SettingsOverviewPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  static const padding = EdgeInsets.fromLTRB(16, 4, 16, 8);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.currentTheme;
    final searching = _query.trim().isNotEmpty;
    final content = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: padding,
            child: SettingsSearchField(controller: _searchController),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (!searching && isAndroid)
                  SliverPadding(
                    padding: padding,
                    sliver: SliverToBoxAdapter(
                      child: _buildAndroidEnvironmentCards(),
                    ),
                  ),
                if (!searching)
                  SliverPadding(
                    padding: padding,
                    sliver: SliverToBoxAdapter(
                      child: _buildStatusOverviewCards(),
                    ),
                  ),
                if (!searching)
                  SliverPadding(
                    padding: padding,
                    sliver: SliverToBoxAdapter(
                      child: consumerWrapper(_buildQuickSettingsCards),
                    ),
                  ),
                if (searching)
                  buildSearchingResults(searching)
                else
                  buildSections(),
              ],
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) {
      return Material(
        color: theme.colorScheme.surface,
        child: content,
      );
    }
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop || !searching) {
          return;
        }
        _clearSearch();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: content,
      ),
    );
  }

  List<SettingsSection> getVisibleSections(BuildContext context) {
    return SettingsSection.values
        .where(
          (section) =>
              isSettingsSectionListVisible(section, context.isCompactScreen),
        )
        .toList();
  }

  ///按当前权限和配置状态实时生成搜索结果，避免隐藏设置项仍出现在搜索中
  List<SettingsSearchItem> _buildSearchResults(BuildContext context) {
    return _buildSettingsSearchItems(context)
        .where(
          (item) =>
              item.matches(_query) &&
              isSettingsSectionAvailable(item.section, context.isCompactScreen),
        )
        .toList();
  }

  ///确认搜索项当前仍可见，防止权限状态刚变化时点击跳到空白设置页
  bool _isSearchItemCurrentlyVisible(
    BuildContext context,
    SettingsSearchItem item,
  ) {
    return _buildSettingsSearchItems(context).any((currentItem) {
      return currentItem.section == item.section &&
          currentItem.searchId == item.searchId &&
          isSettingsSectionAvailable(
            currentItem.section,
            context.isCompactScreen,
          );
    });
  }

  ///构建搜索结构
  Widget buildSearchingResults(bool searching) {
    final searchResults = searching
        ? _buildSearchResults(context)
        : const <SettingsSearchItem>[];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      sliver: Visibility(
        visible: searchResults.isEmpty,
        replacement: SliverList.separated(
          itemCount: searchResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = searchResults[index];
            return SettingsSearchResultTile(
              item: item,
              onTap: () => _onSearchItemTap(context, item),
            );
          },
        ),
        child: const SliverToBoxAdapter(
          child: SettingsEmptySearchTile(),
        ),
      ),
    );
  }

  ///构建一级设置项
  Widget buildSections() {
    final sections = getVisibleSections(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      sliver: SliverList.separated(
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          return SettingsSectionTile(
            section: section,
            selected: widget.selectedSection == section,
            onTap: () => widget.onSectionTap(section),
          );
        },
      ),
    );
  }

  ///构建搜索项
  List<SettingsSearchItem> _buildSettingsSearchItems(BuildContext context) {
    final generatedItems = SettingsSection.values.expand((section) {
      final view = buildSettingsSectionView(section, embedded: true);
      return view?.buildSearchItems(context, ref) ?? <SettingsSearchItem>[];
    }).toList();
    return [
      ...generatedItems,
    ];
  }

  ///清除设置搜索状态，用于返回键优先退出搜索而不是关闭设置页
  void _clearSearch() {
    _searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSearchItemTap(BuildContext context, SettingsSearchItem item) {
    if (!_isSearchItemCurrentlyVisible(context, item)) {
      setState(() {});
      return;
    }
    if (widget.onSearchItemTap != null) {
      widget.onSearchItemTap!(item);
      return;
    }
    widget.onSectionTap(item.section);
  }

  Widget _buildStatusOverviewCards() {
    return const SizedBox.shrink();
    //todo
    // return Obx(
    //   () => SettingsOverviewGroup(
    //     children: [
    //       SettingsOverviewTile(
    //         icon: Icons.admin_panel_settings_outlined,
    //         title: TranslationKey.permissionSettingsGroupName.tr,
    //         subtitle: _permissionSummaryText(),
    //         tone: _permissionIssueCount() == 0 ? Colors.green : Colors.orange,
    //         trailing: const Icon(
    //           Icons.chevron_right_rounded,
    //           color: Colors.blueGrey,
    //         ),
    //         onTap: () => widget.onSectionTap(SettingsSection.permission),
    //         selected: widget.selectedSection == SettingsSection.permission,
    //         visible: (isAndroid || isIOS) && _permissionIssueCount() > 0,
    //       ),
    //       // Keep relay status visible at the top while its detailed controls live in the relay page.
    //       SettingsOverviewTile(
    //         icon: Icons.cloud_sync_outlined,
    //         title: TranslationKey.forwardSettingsGroupName.tr,
    //         subtitle: forwardOverviewStatusText(
    //           way: appConfig.forwardWay,
    //           enabled: appConfig.enableForward,
    //           status: settingsController.forwardServerStatus.value,
    //         ),
    //         subtitleIcon: forwardWayIcon(appConfig.forwardWay),
    //         subtitleTooltip: forwardWayLabel(appConfig.forwardWay),
    //         tone: forwardOverviewTone(
    //           way: appConfig.forwardWay,
    //           enabled: appConfig.enableForward,
    //           status: settingsController.forwardServerStatus.value,
    //         ),
    //         trailing: appConfig.forwardWay == ForwardWay.none
    //             ? const Icon(
    //                 Icons.chevron_right_rounded,
    //                 color: Colors.blueGrey,
    //               )
    //             : Row(
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: [
    //                   Switch(
    //                     value: appConfig.enableForward,
    //                     onChanged: (checked) =>
    //                         _toggleForward(context, checked),
    //                   ),
    //                   const Icon(
    //                     Icons.chevron_right_rounded,
    //                     color: Colors.blueGrey,
    //                   ),
    //                 ],
    //               ),
    //         onTap: () => widget.onSectionTap(SettingsSection.forward),
    //         selected: widget.selectedSection == SettingsSection.forward,
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildQuickSettingsCards(BuildContext context, WidgetRef ref) {
    final quickSettings = ref.watch(quickSettingsProvider).requireValue;
    return SettingsOverviewGroup(
      children: [
        SettingsOverviewTile(
          icon: Icons.power_settings_new_rounded,
          title: TranslationKey.commonSettingsRunAtStartup.tr,
          subtitle: '',
          tone: Colors.blueGrey,
          trailing: Switch(
            value: quickSettings.launchAtStartup,
            onChanged: _toggleLaunchAtStartup,
          ),
          onTap: () => {},
          visible: isDesktop,
        ),
        SettingsOverviewTile(
          icon: Icons.vertical_align_bottom_rounded,
          title: TranslationKey.commonSettingsRunMinimize.tr,
          subtitle: '',
          tone: Colors.blueGrey,
          trailing: Switch(
            value: quickSettings.startMini,
            onChanged: (v) async {
              final db = ref.read(appDbProvider).requireValue;
              await db.configDao.addOrUpdate(ConfigKey.startMini, v.toString());
              ref.invalidate(startMiniProvider);
            },
          ),
          onTap: () => {},
          visible: isDesktop,
        ),
        SettingsOverviewTile(
          icon: _themeIcon(quickSettings.appTheme),
          title: TranslationKey.commonSettingsTheme.tr,
          subtitle: '',
          tone: Colors.blueGrey,
          trailing: ThemeModeSelector(
            value: quickSettings.appTheme,
            onChanged: (mode) async {
              await Future.delayed(100.ms);
              if (!context.mounted) {
                return;
              }
              await _setTheme(context, mode);
            },
          ),
          onTap: () {},
        ),
        SettingsOverviewTile(
          icon: Icons.language_rounded,
          title: TranslationKey.language.tr,
          subtitle: '',
          tone: Colors.blueGrey,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.blueGrey,
          ),
          onTap: () => widget.onSectionTap(SettingsSection.language),
          selected: widget.selectedSection == SettingsSection.language,
        ),
      ],
    );
  }

  int _permissionIssueCount() {
    return 0;
    // var count = 0;
    // if (isAndroid) {
    //   if (!settingsController.hasNotifyPerm.value) count++;
    //   if (!settingsController.hasFloatPerm.value) count++;
    //   if (!settingsController.hasIgnoreBattery.value) count++;
    //   if (!settingsController.hasSmsReadPerm.value) count++;
    //   if (!settingsController.hasClipboardPerm.value) count++;
    //   if (!settingsController.hasAccessibilityPerm.value && appConfig.sourceRecord && !appConfig.ignoreAccessibility) count++;
    //   if ((!settingsController.hasNotificationRecordPerm.value && appConfig.enableRecordNotification) || (settingsController.hasNotificationRecordPerm.value && !appConfig.enableRecordNotification)) {
    //     count++;
    //   }
    // } else if (isIOS) {
    //   if (!settingsController.hasNotifyPerm.value) count++;
    //   if (!settingsController.hasIOSPhotosPerm.value) count++;
    // }
    // return count;
  }

  String _permissionSummaryText() {
    final count = _permissionIssueCount();
    if (count == 0) {
      return isAndroid || isIOS
          ? TranslationKey.settingsOverviewPermissionNormal.tr
          : TranslationKey.none.tr;
    }
    return TranslationKey.settingsOverviewPermissionIssueCount.trParams({
      'count': count.toString(),
    });
  }

  Future<void> _toggleForward(BuildContext context, bool checked) async {
    //todo
    // final useServer = appConfig.forwardWay == ForwardWay.server;
    // if (checked && useServer && appConfig.forwardServer == null) {
    //   Global.showSnackBarErr(
    //     context: context,
    //     text: TranslationKey.forwardSettingsForwardEnableRequiredText.tr,
    //   );
    //   return;
    // }
    // final useWebdav = appConfig.forwardWay == ForwardWay.webdav;
    // if (checked && useWebdav && appConfig.webDAVConfig == null) {
    //   Global.showSnackBarErr(
    //     context: context,
    //     text: TranslationKey.forwardSettingsForwardEnableRequiredWebDAVText.tr,
    //   );
    //   return;
    // }
    // final useS3 = appConfig.forwardWay == ForwardWay.s3;
    // if (checked && useS3 && appConfig.s3Config == null) {
    //   Global.showSnackBarErr(
    //     context: context,
    //     text: TranslationKey.forwardSettingsForwardEnableRequiredS3Text.tr,
    //   );
    //   return;
    // }
    // await appConfig.setEnableForward(checked);
    // if (checked) {
    //   if (useServer) {
    //     sktService.connectForwardServer(true);
    //   } else {
    //     storageService.start();
    //   }
    // } else {
    //   if (useServer) {
    //     sktService.disConnectForwardServer();
    //   } else {
    //     storageService.stop();
    //   }
    // }
  }

  IconData _themeIcon(ThemeMode mode) {
    if (mode == ThemeMode.light) {
      return Icons.light_mode_outlined;
    }
    if (mode == ThemeMode.dark) {
      return Icons.dark_mode_outlined;
    }
    return Icons.brightness_auto_outlined;
  }

  Future<void> _setTheme(BuildContext context, ThemeMode mode) async {
    final appTheme = await ref.read(appThemeProvider.future);
    if (mode == appTheme) {
      return;
    }
    final db = await ref.read(appDbProvider.future);
    await db.configDao.addOrUpdate(ConfigKey.appTheme, mode.name);
    if(!context.mounted){
      return;
    }
    var isDark = mode == ThemeMode.dark;
    if(mode == ThemeMode.system){
      isDark = context.isPlatformDarkMode;
    }
    context.updateTheme(isDark, onAnimationFinish: () {
      //todo
      // final currentBg = settingsController.envStatusBgColor.value;
      // if (currentBg != null) {
      //   settingsController.envStatusBgColor.value = settingsController.warningBgColor;
      // }
    });
    //todo
    // Get.find<AndroidChannelService>().setHistoryFloatThemeMode(mode);
    // final currentBg = settingsController.envStatusBgColor.value;
    // if (currentBg != null) {
    //   settingsController.envStatusBgColor.value = settingsController.warningBgColor;
    // }
    ref.invalidate(appThemeProvider);
  }

  Future<void> _toggleLaunchAtStartup(bool checked) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    final appPath = startupExecutablePath;
    launchAtStartup.setup(
      appName: appName,
      appPath: appPath,
    );
    if (checked) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    ref.invalidate(appLaunchAtStartupProvider);
  }

  Widget _buildAndroidEnvironmentCards() {
    return const SizedBox.shrink();
    //todo
    // return Column(
    //   children: [
    //     Obx(() {
    //       return EnvironmentStatusCard(
    //         icon: Obx(() => settingsController.envStatusIcon.value),
    //         backgroundColor: settingsController.envStatusBgColor.value,
    //         tipContent: Obx(() => settingsController.envStatusTipContent.value),
    //         tipDesc: Obx(() => settingsController.envStatusTipDesc.value),
    //         action: Obx(() {
    //           return settingsController.envStatusAction.value ?? const SizedBox.shrink();
    //         }),
    //         onTap: settingsController.onEnvironmentStatusCardClick,
    //       );
    //     }),
    //     Obx(
    //           () => Visibility(
    //         visible: appConfig.workingMode == EnvironmentType.shizuku || appConfig.workingMode == EnvironmentType.root,
    //         child: SettingHeader(
    //           icon: const Icon(
    //             Icons.developer_mode,
    //             size: 17,
    //           ),
    //           title: TranslationKey.clipboardListeningWay.tr,
    //           tips: Tooltip(
    //             message: TranslationKey.clipboardListeningWayTips.tr,
    //             child: GestureDetector(
    //               child: const MouseRegion(
    //                 cursor: SystemMouseCursors.click,
    //                 child: Icon(
    //                   Icons.info_outline,
    //                   color: Colors.blueGrey,
    //                   size: 15,
    //                 ),
    //               ),
    //               onTap: () async {
    //                 Global.showTipsDialog(
    //                   context: context,
    //                   text: TranslationKey.clipboardListeningWayTipsDetail.tr,
    //                 );
    //               },
    //             ),
    //           ),
    //           padding: const EdgeInsets.only(bottom: 8, left: 8),
    //         ),
    //       ),
    //     ),
    //     Obx(
    //           () => Visibility(
    //         visible: appConfig.workingMode == EnvironmentType.shizuku || appConfig.workingMode == EnvironmentType.root,
    //         child: Row(
    //           children: [
    //             Expanded(
    //               child: Obx(
    //                     () => ClipboardListeningWaySettingCard(
    //                   cardMargin: const EdgeInsets.only(left: 0, right: 3),
    //                   icon: Icons.visibility_off,
    //                   name: ClipboardListeningWay.hiddenApi.tr,
    //                   selected: appConfig.clipboardListeningWay == ClipboardListeningWay.hiddenApi,
    //                   onTap: () {
    //                     if (appConfig.clipboardListeningWay == ClipboardListeningWay.hiddenApi) {
    //                       return;
    //                     }
    //                     Global.showTipsDialog(
    //                       context: context,
    //                       text: TranslationKey.clipboardListeningWayToggleConfirmContent.trParams({'way': ClipboardListeningWay.hiddenApi.tr}),
    //                       showCancel: true,
    //                       onOk: () async {
    //                         appConfig.setClipboardListeningWay(ClipboardListeningWay.hiddenApi);
    //                         await clipboardManager.stopListening();
    //                         clipboardManager.startListening(
    //                           env: appConfig.workingMode,
    //                           way: ClipboardListeningWay.hiddenApi,
    //                           notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
    //                         );
    //                       },
    //                     );
    //                   },
    //                 ),
    //               ),
    //             ),
    //             Expanded(
    //               child: Obx(
    //                     () => ClipboardListeningWaySettingCard(
    //                   cardMargin: const EdgeInsets.only(right: 0, left: 3),
    //                   icon: Icons.list_alt,
    //                   name: ClipboardListeningWay.logs.tr,
    //                   selected: appConfig.clipboardListeningWay == ClipboardListeningWay.logs,
    //                   onTap: () {
    //                     if (appConfig.clipboardListeningWay == ClipboardListeningWay.logs) {
    //                       return;
    //                     }
    //                     Global.showTipsDialog(
    //                       context: context,
    //                       text: TranslationKey.clipboardListeningWayToggleConfirmContent.trParams({'way': ClipboardListeningWay.logs.tr}),
    //                       showCancel: true,
    //                       onOk: () async {
    //                         appConfig.setClipboardListeningWay(ClipboardListeningWay.logs);
    //                         await clipboardManager.stopListening();
    //                         clipboardManager.startListening(
    //                           env: appConfig.workingMode,
    //                           way: ClipboardListeningWay.logs,
    //                           notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
    //                         );
    //                       },
    //                     );
    //                   },
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }
}
