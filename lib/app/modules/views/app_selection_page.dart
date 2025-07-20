import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/memory_image_with_not_found.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AppSelectionPage extends StatefulWidget {
  final bool distinguishSystemApps;
  final int limit;
  final Future<List<LocalAppInfo>> Function() loadAppInfos;
  final void Function(List<LocalAppInfo> selected) onSelectedDone;

  const AppSelectionPage({
    super.key,
    this.distinguishSystemApps = false,
    required this.loadAppInfos,
    required this.onSelectedDone,
    this.limit = -1,
  });

  @override
  State<StatefulWidget> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> with SingleTickerProviderStateMixin {
  var originAppList = List<LocalAppInfo>.empty(growable: true);
  var searchResultList = List<LocalAppInfo>.empty(growable: true);
  final selected = <String>{}.obs;
  static final borderRadius = BorderRadius.circular(12.0);
  static const itemPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  static const checkIcon = IconButton(
    onPressed: null,
    icon: Icon(
      Icons.check_circle,
      color: Colors.lightBlue,
    ),
  );
  late final TabController tabController;
  final emptyContent = EmptyContent();

  List<Tab> get tabs => [
        Tab(text: TranslationKey.userApp.tr),
        Tab(text: TranslationKey.systemApp.tr),
      ];

  List<LocalAppInfo> get systemApps => searchResultList.where((item) => item.isSystemApp).toList();

  List<LocalAppInfo> get userApps => searchResultList.where((item) => !item.isSystemApp).toList();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this, initialIndex: 0);
    widget.loadAppInfos().then((list) {
      setState(() {
        list.sort((a, b) => a.name.compareTo(b.name));
        originAppList = list;
        searchResultList = list;
      });
    });
  }

  Widget renderAppList(List<LocalAppInfo> list) {
    const defaultSize = MemImageWithNotFound.defaultIconSize;
    if (list.isEmpty) {
      return emptyContent;
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext context, int i) {
        final app = list[i];
        return SizedBox(
          height: 70,
          child: Card(
            elevation: 0,
            child: InkWell(
              onTap: () {
                if (widget.limit == 1) {
                  selected.clear();
                  selected.add(app.appId);
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
                          MemImageWithNotFound(
                            bytes: app.iconBytes,
                            width: defaultSize * 1.5,
                            height: defaultSize * 1.5,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: app.name,
                                  child: Text(
                                    app.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                Tooltip(
                                  message: app.appId,
                                  child: Text(
                                    app.appId,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: selected.contains(app.appId),
                        child: checkIcon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> onRefresh() async {
    final list = await widget.loadAppInfos();
    setState(() {
      originAppList = list;
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
          TabBar(
            tabs: tabs,
            controller: tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                RefreshIndicator(
                  onRefresh: onRefresh,
                  child: renderAppList(userApps),
                ),
                RefreshIndicator(
                  onRefresh: onRefresh,
                  child: renderAppList(systemApps),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: onRefresh,
        child: renderAppList(userApps),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: TextField(
            decoration: InputDecoration(
              hintText: TranslationKey.search.tr,
              hintStyle: const TextStyle(color: Colors.grey),
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
        Expanded(child: body),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: Row(
        children: [
          Expanded(
            child: Text(TranslationKey.selectApplication.tr),
          ),
          Tooltip(
            message: TranslationKey.confirm.tr,
            child: Obx(
              () => IconButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final result = originAppList.where((item) => selected.contains(item.appId)).toList(growable: false);
                        widget.onSelectedDone(result);
                        Get.back();
                      },
                icon: const Icon(Icons.check),
              ),
            ),
          ),
        ],
      ),
      icon: Icon(MdiIcons.listBoxOutline),
      child: renderBody(),
    );
  }
}
