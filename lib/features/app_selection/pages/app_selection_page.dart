import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/shared/extensions/list_extension.dart';
import 'package:clipshare/features/app_selection/models/local_app_info.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:clipshare/shared/widgets/memory_image_with_not_found.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:sliver_sticky_collapsable_panel/utils/sliver_sticky_collapsable_panel_controller.dart';
import 'package:sliver_sticky_collapsable_panel/widgets/sliver_sticky_collapsable_panel.dart';

/// 应用选择页：按设备分组展示应用并支持多选。
///
/// 应用数据与设备名均由外部回调提供，页面本身不访问任何数据源。
class AppSelectionPage extends StatefulWidget {
  final bool distinguishSystemApps;
  final int limit;
  final Future<List<LocalAppInfo>> Function() loadAppInfos;
  final String Function(String devId) loadDeviceName;
  final Iterable<String>? selectedIds;
  final void Function(List<LocalAppInfo> selected) onSelectedDone;

  const AppSelectionPage({
    super.key,
    this.distinguishSystemApps = false,
    required this.loadAppInfos,
    required this.onSelectedDone,
    this.limit = -1,
    required this.loadDeviceName,
    this.selectedIds,
  });

  @override
  State<StatefulWidget> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> with SingleTickerProviderStateMixin {
  static final borderRadius = BorderRadius.circular(12.0);
  static const itemPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  static const checkIcon = IconButton(onPressed: null, icon: Icon(Icons.check_circle, color: Colors.lightBlue));
  static final aniDuration = 200.ms;
  final emptyContent = const EmptyContent();
  final appIconBytesCached = <String, Uint8List>{};
  var originAppList = List<LocalAppInfo>.empty(growable: true);
  var searchResultList = List<LocalAppInfo>.empty(growable: true);
  final selected = <String>{};
  final scrollController = ScrollController();
  late final TabController tabController;
  var loading = true;
  var showSearchTextInput = false;

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

  Widget renderAppList(List<LocalAppInfo> list) {
    const defaultSize = MemImageWithNotFound.defaultIconSize;
    if (list.isEmpty) {
      return emptyContent;
    }
    final groups = list.groupBy((item) => item.devId);
    return CustomScrollView(
      controller: scrollController,
      slivers: groups.keys.map((devId) {
        return SliverStickyCollapsablePanel(
          scrollController: scrollController,
          controller: StickyCollapsablePanelController(key: devId),
          headerBuilder: (context, status) {
            final isExpanded = status.isExpanded;
            return Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              child: Padding(
                padding: const EdgeInsetsGeometry.symmetric(horizontal: 5),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(child: Text(widget.loadDeviceName(devId))),
                      AnimatedRotation(duration: aniDuration, turns: isExpanded ? 0 : 0.5, child: const Icon(Icons.expand_more)),
                    ],
                  ),
                ),
              ),
            );
          },
          sliverPanel: SliverList.list(
            children: groups[devId]!.map((app) {
              Uint8List iconBytes;
              if (app.id == 0) {
                if (!appIconBytesCached.containsKey(app.appId)) {
                  appIconBytesCached[app.appId] = base64Decode(app.iconB64);
                }
                iconBytes = appIconBytesCached[app.appId]!;
              } else {
                iconBytes = app.iconBytes;
              }
              return SizedBox(
                height: 75,
                child: Card(
                  elevation: 0,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (widget.limit == 1) {
                          selected
                            ..clear()
                            ..add(app.appId);
                        } else {
                          if (selected.contains(app.appId)) {
                            selected.remove(app.appId);
                          } else {
                            if (widget.limit > 0 && selected.length >= widget.limit) {
                              //达到选择的数量上限
                              return;
                            }
                            selected.add(app.appId);
                          }
                        }
                      });
                    },
                    borderRadius: borderRadius,
                    child: Padding(
                      padding: itemPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                MemImageWithNotFound(bytes: iconBytes, width: defaultSize * 1.5, height: defaultSize * 1.5),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Tooltip(
                                        message: app.name,
                                        child: Text(app.name, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 18)),
                                      ),
                                      Tooltip(
                                        message: app.appId,
                                        child: Text(app.appId, overflow: TextOverflow.ellipsis, maxLines: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(visible: selected.contains(app.appId), child: checkIcon),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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

  /// 原 RoundedScaffold.title 内容：应用搜索栏与确认按钮。
  Widget buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Visibility(
            visible: showSearchTextInput,
            replacement: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(TranslationKey.selectApplication.tr),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showSearchTextInput = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            child: TextField(
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: TranslationKey.search.tr,
                hintStyle: const TextStyle(fontSize: 13),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showSearchTextInput = false;
                      searchResultList = originAppList;
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (text) {
                setState(() {
                  searchResultList = originAppList.where((appInfo) {
                    if (appInfo.appId.containsIgnoreCase(text)) {
                      return true;
                    }
                    return appInfo.name.containsIgnoreCase(text);
                  }).toList();
                });
              },
            ),
          ),
        ),
        Tooltip(
          message: TranslationKey.confirm.tr,
          child: IconButton(
            onPressed: selected.isEmpty
                ? null
                : () {
                    final result = originAppList.where((item) => selected.contains(item.appId)).toList(growable: false);
                    widget.onSelectedDone(result);
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //todo 原 RoundedScaffold 容器（小屏 AppBar / 桌面标题栏 / 圆角）待新架构容器替代，
    //     此处暂用 Scaffold 承载其 title 内容与 child。
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Row(
                children: [
                  const Icon(MdiIcons.listBoxOutline),
                  const SizedBox(width: 5),
                  Expanded(child: buildTitle(context)),
                ],
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
        ),
      ),
    );
  }
}
