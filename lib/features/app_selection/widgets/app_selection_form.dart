import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/list_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare/shared/widgets/memory_image_with_not_found.dart';
import 'package:flutter/material.dart';
import 'package:sliver_sticky_collapsable_panel/utils/sliver_sticky_collapsable_panel_controller.dart';
import 'package:sliver_sticky_collapsable_panel/widgets/sliver_sticky_collapsable_panel.dart';

import 'app_selection_search_bar.dart';

/// 应用选择共享内容组件：负责加载、搜索过滤与多选列表展示。
///
/// 自身不持有标题栏与确认按钮，由宿主（小屏页面/大屏弹窗）承载；
/// [showSearchBar] 为 true 时在顶部渲染共享搜索栏，过滤结果实时驱动列表。
class AppSelectionForm extends StatefulWidget {
  final bool distinguishSystemApps;
  final int limit;
  final Future<List<LocalAppInfo>> Function() loadAppInfos;
  final String Function(String devId) loadDeviceName;
  final Iterable<String>? selectedIds;
  final bool showSearchBar;

  /// 选中状态变化时同步更新，宿主据此控制确认按钮是否可点；为空时不通知。
  final ValueNotifier<bool>? canConfirmNotifier;

  const AppSelectionForm({
    super.key,
    this.distinguishSystemApps = false,
    required this.limit,
    required this.loadAppInfos,
    required this.loadDeviceName,
    this.selectedIds,
    this.showSearchBar = false,
    this.canConfirmNotifier,
  });

  @override
  State<AppSelectionForm> createState() => AppSelectionFormState();
}

class AppSelectionFormState extends State<AppSelectionForm> with SingleTickerProviderStateMixin {
  static final aniDuration = 200.ms;
  final emptyContent = const EmptyContent();
  final appIconBytesCached = <String, Uint8List>{};
  var originAppList = List<LocalAppInfo>.empty(growable: true);
  var searchResultList = List<LocalAppInfo>.empty(growable: true);
  final selected = <String>{};
  final scrollController = ScrollController();
  late final TabController tabController;
  var loading = true;

  List<Tab> get tabs => [Tab(text: TranslationKey.userApp.tr), Tab(text: TranslationKey.systemApp.tr)];

  List<LocalAppInfo> get systemApps => searchResultList.where((item) => item.isSystemApp).toList();

  List<LocalAppInfo> get userApps => searchResultList.where((item) => !item.isSystemApp).toList();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this, initialIndex: 0);
    if (widget.selectedIds != null) {
      selected.addAll(widget.selectedIds!);
    }
    _notifySelectionChanged();
    widget.loadAppInfos().then((list) {
      if (!mounted) {
        return;
      }
      setState(() {
        list.sort((a, b) => a.name.compareTo(b.name));
        originAppList = list;
        searchResultList = list;
        loading = false;
      });
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// 选中集合变化时同步宿主确认按钮的可点状态。
  void _notifySelectionChanged() {
    widget.canConfirmNotifier?.value = selected.isNotEmpty;
  }

  /// 按关键字过滤应用列表；空关键字恢复全量列表。
  void applySearch(String keyword) {
    setState(() {
      searchResultList = keyword.isEmpty
          ? originAppList
          : originAppList.where((appInfo) {
              if (appInfo.appId.containsIgnoreCase(keyword)) {
                return true;
              }
              return appInfo.name.containsIgnoreCase(keyword);
            }).toList();
    });
  }

  /// 按当前选中项从全量列表中提取结果，供宿主确认后回传。
  List<LocalAppInfo> buildResult() {
    if (selected.isEmpty) {
      return const [];
    }
    return originAppList.where((item) => selected.contains(item.appId)).toList(growable: false);
  }

  /// 单个应用条目点击：单选替换或多选切换，并同步选中状态。
  void _toggleSelected(LocalAppInfo app) {
    setState(() {
      if (widget.limit == 1) {
        selected
          ..clear()
          ..add(app.appId);
      } else if (selected.contains(app.appId)) {
        selected.remove(app.appId);
      } else {
        if (widget.limit > 0 && selected.length >= widget.limit) {
          //达到选择的数量上限
          return;
        }
        selected.add(app.appId);
      }
    });
    _notifySelectionChanged();
  }

  /// 应用列表渲染：按设备分组，分组头为轻量来源筛选样式，条目为紧凑行。
  Widget renderAppList(List<LocalAppInfo> list) {
    if (list.isEmpty) {
      return emptyContent;
    }
    // 小屏下给首个分组头顶部留出外边距，避免紧贴页面顶部；水平边距仅小屏保留。
    final headerTopMargin = context.isCompactScreen ? 8.0 : 0.0;
    final horizontalPadding = context.isCompactScreen ? 12.0 : 0.0;
    final groupEntries = list.groupBy((item) => item.devId).entries.toList();
    return CustomScrollView(
      controller: scrollController,
      slivers: groupEntries.asMap().entries.map((groupEntry) {
        final groupIndex = groupEntry.key;
        final devId = groupEntry.value.key;
        final apps = groupEntry.value.value;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverStickyCollapsablePanel(
            scrollController: scrollController,
            controller: StickyCollapsablePanelController(key: devId),
            headerBuilder: (context, status) => _GroupHeader(
              title: widget.loadDeviceName(devId),
              isExpanded: status.isExpanded,
              topMargin: groupIndex == 0 ? headerTopMargin : 0,
            ),
            sliverPanel: SliverList.list(
              children: apps.asMap().entries.map((itemEntry) {
                final app = itemEntry.value;
                Uint8List iconBytes;
                if (app.id == 0) {
                  iconBytes = appIconBytesCached.putIfAbsent(app.appId, () => base64Decode(app.iconB64));
                } else {
                  iconBytes = app.iconBytes;
                }
                return _AppListItem(
                  app: app,
                  iconBytes: iconBytes,
                  selected: selected.contains(app.appId),
                  isLast: itemEntry.key == apps.length - 1,
                  onTap: () => _toggleSelected(app),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> onRefresh() async {
    setState(() {
      loading = true;
    });
    final list = await widget.loadAppInfos();
    if (!mounted) {
      return;
    }
    setState(() {
      originAppList = list;
      searchResultList = list;
      loading = false;
    });
  }

  Widget renderBody() {
    if (originAppList.isEmpty) {
      return emptyContent;
    }
    Widget body;
    if (widget.distinguishSystemApps) {
      body = Column(
        children: [
          TabBar(tabs: tabs, controller: tabController),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                RefreshIndicator(onRefresh: onRefresh, child: renderAppList(userApps)),
                RefreshIndicator(onRefresh: onRefresh, child: renderAppList(systemApps)),
              ],
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(onRefresh: onRefresh, child: renderAppList(searchResultList));
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSearchBar)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AppSelectionSearchBar(
              initiallyExpanded: true,
              onSearchChanged: applySearch,
            ),
          ),
        Expanded(
          child: Visibility(
            visible: !loading,
            replacement: const Loading(
              width: 40,
            ),
            child: renderBody(),
          ),
        ),
      ],
    );
  }
}

/// 轻量来源分组头：默认透明底，hover 时极浅灰蓝背景；左侧设备名、右侧展开箭头。
class _GroupHeader extends StatefulWidget {
  final String title;
  final bool isExpanded;
  final double topMargin;

  const _GroupHeader({
    required this.title,
    required this.isExpanded,
    this.topMargin = 0,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // 分组头底色随宿主背景（小屏页面背景/大屏弹窗背景），滚动时遮挡其下滚过的条目。
    final baseColor = context.isCompactScreen
        ? colorScheme.surface
        : (theme.dialogTheme.backgroundColor ?? colorScheme.surface);
    final backgroundColor = _hovered
        ? Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.06), baseColor)
        : baseColor;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(top: widget.topMargin, bottom: 6),
        height: 36,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              AnimatedRotation(
                duration: AppSelectionFormState.aniDuration,
                turns: widget.isExpanded ? 0 : 0.5,
                child: Icon(
                  Icons.expand_more,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 紧凑应用条目：图标 + 名称 + 应用标识 + 选中对勾；悬停/选中背景使用主题语义色。
class _AppListItem extends StatefulWidget {
  final LocalAppInfo app;
  final Uint8List iconBytes;
  final bool selected;

  /// 是否为该分组最后一条，最后一条不渲染分隔线。
  final bool isLast;
  final VoidCallback onTap;

  const _AppListItem({
    required this.app,
    required this.iconBytes,
    required this.selected,
    this.isLast = false,
    required this.onTap,
  });

  @override
  State<_AppListItem> createState() => _AppListItemState();
}

class _AppListItemState extends State<_AppListItem> {
  var _hovered = false;
  static const _iconSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.selected
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : _hovered
                      ? colorScheme.primary.withValues(alpha: 0.06)
                      : Colors.transparent,
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: MemImageWithNotFound(
                        bytes: widget.iconBytes,
                        width: _iconSize,
                        height: _iconSize,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            message: app.name,
                            child: Text(
                              app.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Tooltip(
                            message: app.appId,
                            child: Text(
                              app.appId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.selected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (!widget.isLast) ...[
            Divider(
              height: 1,
              thickness: 0.5,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}