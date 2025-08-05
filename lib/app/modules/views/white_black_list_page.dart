import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/white_black_rule.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/dialog/filter_rule_add_dialog.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhiteBlackListPage extends StatefulWidget {
  final WhiteBlackMode showMode;
  final WhiteBlackMode currentMode;
  final String title;

  ///mode不为all时生效
  final bool enabled;
  final List<FilterRule>? blacklist;
  final List<FilterRule>? whitelist;
  final void Function(WhiteBlackMode mode, Map<WhiteBlackMode, List<FilterRule>> data)? onDone;
  final void Function(WhiteBlackMode mode, bool enabled)? onModeChanged;

  const WhiteBlackListPage({
    super.key,
    required this.title,
    required this.showMode,
    this.currentMode = WhiteBlackMode.black,
    this.enabled = true,
    this.onModeChanged,
    this.onDone,
    this.blacklist,
    this.whitelist,
  });

  @override
  State<StatefulWidget> createState() => _WhiteBlackListPageState();
}

class _WhiteBlackListPageState extends State<WhiteBlackListPage> {
  final appIconSize = 17.0;
  final blacklist = <FilterRule>[].obs;
  final whitelist = <FilterRule>[].obs;
  final appConfig = Get.find<ConfigService>();
  final isBlacklistMode = true.obs;
  static const _defaultBorderRadius = 8.0;
  static const _topBorder = BorderRadius.only(
    topLeft: Radius.circular(_defaultBorderRadius),
    topRight: Radius.circular(_defaultBorderRadius),
  );
  static const _bottomBorder = BorderRadius.only(
    bottomLeft: Radius.circular(_defaultBorderRadius),
    bottomRight: Radius.circular(_defaultBorderRadius),
  );
  static const _allBorder = BorderRadius.all(Radius.circular(_defaultBorderRadius));

  final allContent = Text(
    TranslationKey.all.tr,
    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
  );

  @override
  void initState() {
    super.initState();
    isBlacklistMode.value = widget.currentMode != WhiteBlackMode.white;
    blacklist.value = widget.blacklist ?? [];
    whitelist.value = widget.whitelist ?? [];
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingHeader(
            title: isBlacklistMode.value ? TranslationKey.blacklistRules.tr : TranslationKey.whitelistRules.tr,
            icon: const Icon(
              Icons.list_alt_sharp,
              color: Colors.blueGrey,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.dialog(
              FilterRuleAddDialog(
                mode: isBlacklistMode.value ? WhiteBlackMode.black : WhiteBlackMode.white,
                onDone: (data) {
                  onRuleDialogConfirm(context, -1, data);
                },
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 5),
              Text(TranslationKey.add.tr),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildRuleList(BuildContext context, bool showConfirmBtn) {
    final ruleList = isBlacklistMode.value ? blacklist : whitelist;
    return Column(
      children: [
        buildHeader(context),
        Expanded(
          child: Obx(
            () => Visibility(
              visible: ruleList.isEmpty,
              replacement: Obx(
                () {
                  final length = ruleList.length;
                  return SingleChildScrollView(
                    child: Column(
                      children: List.generate(ruleList.length, (i) {
                        final item = ruleList[i];
                        final borderRadius = length == 1
                            ? _allBorder
                            : i == 0
                            ? _topBorder
                            : _bottomBorder;
                        return SettingCard<FilterRule>(
                          title: DefaultTextStyle(
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            child: Row(
                              children: [
                                Text("${TranslationKey.content.tr}: ${item.isAllContent ? "" : item.content}"),
                                if (item.isAllContent) allContent,
                              ],
                            ),
                          ),
                          description: PlatformExt.isMobile
                              ? Row(
                                  children: [
                                    Text("${TranslationKey.source.tr}: "),
                                    if (item.isAllApp) allContent,
                                    ...item.appIds.map(
                                      (appId) => AppIcon(
                                        appId: appId,
                                        iconSize: appIconSize,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          value: item,
                          action: (value) {
                            return Row(
                              children: [
                                // Tooltip(
                                //   message: item.needSync ? "同步" : "不同步",
                                //   child: Icon(
                                //     item.needSync ? Icons.sync : Icons.sync_disabled,
                                //     color: Colors.blueGrey,
                                //     size: 18,
                                //   ),
                                // ),
                                Tooltip(
                                  message: item.enable ? TranslationKey.enable.tr : TranslationKey.disable.tr,
                                  child: Checkbox(
                                    value: value.enable,
                                    onChanged: (v) {
                                      ruleList[i] = item.copyWith(enable: v);
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: TranslationKey.delete.tr,
                                  child: IconButton(
                                    onPressed: () {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: TranslationKey.deleteRecordAck.tr,
                                        showCancel: true,
                                        onOk: () {
                                          ruleList.removeAt(i);
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.blueGrey),
                                  ),
                                ),
                              ],
                            );
                          },
                          onTap: () {
                            Get.dialog(
                              FilterRuleAddDialog(
                                mode: isBlacklistMode.value ? WhiteBlackMode.black : WhiteBlackMode.white,
                                data: ruleList[i],
                                onDone: (data) {
                                  onRuleDialogConfirm(context, i, data);
                                },
                              ),
                            );
                          },
                          borderRadius: borderRadius,
                        );
                      }),
                    ),
                  );
                },
              ),
              child: EmptyContent(),
            ),
          ),
        ),
        if (showConfirmBtn)
          Container(
            width: 150,
            margin: const EdgeInsets.only(bottom: 10),
            child: TextButton(
              onPressed: () => onConfirmClicked(context),
              child: Text(TranslationKey.confirm.tr),
            ),
          ),
      ],
    );
  }

  void onRuleDialogConfirm(BuildContext context, int index, FilterRule data) {
    final ruleList = isBlacklistMode.value ? blacklist : whitelist;
    if (data.content.isEmpty) {
      if (PlatformExt.isDesktop) {
        Global.showTipsDialog(context: context, text: TranslationKey.contentCannotEmpty.tr);
        return;
      } else if (data.appIds.isEmpty) {
        Global.showTipsDialog(context: context, text: TranslationKey.contentAndSourceCannotEmpty.tr);
        return;
      }
    }
    if (index < 0) {
      ruleList.add(data);
    } else {
      ruleList[index] = data;
    }
    Get.back();
  }

  void onConfirmClicked(BuildContext context) {
    Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
    Get.back();
    widget.onDone?.call(isBlacklistMode.value ? WhiteBlackMode.black : WhiteBlackMode.white, {
      WhiteBlackMode.black: blacklist.value,
      WhiteBlackMode.white: whitelist.value,
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    final showAppBar = appConfig.isSmallScreen;
    final body = Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
      child: Column(
        children: [
          Card(
            borderOnForeground: true,
            color: Theme.of(context).cardTheme.color,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final text = isBlacklistMode.value ? TranslationKey.enableBlackList.tr : TranslationKey.enableWhiteList.tr;
                          return Text(text);
                        }),
                        const SizedBox(height: 5),
                        Obx(() {
                          final text = isBlacklistMode.value ? TranslationKey.enableBlackListTips.tr : TranslationKey.enableWhiteListTips.tr;
                          return Text(
                            text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Obx(
                    () {
                      //判断当前模式是什么模式
                      final isAllMode = widget.showMode == WhiteBlackMode.all;
                      final currentMode = isBlacklistMode.value ? WhiteBlackMode.black : WhiteBlackMode.white;
                      bool value;
                      if (isAllMode) {
                        value = isBlacklistMode.value;
                      } else {
                        value = widget.enabled;
                      }
                      return Switch(
                        value: value,
                        onChanged: (checked) {
                          var mode = widget.showMode;
                          if (isAllMode) {
                            mode = currentMode;
                            checked = currentMode != WhiteBlackMode.black;
                            isBlacklistMode.value = checked;
                          }
                          widget.onModeChanged?.call(mode, checked);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFFFE0B2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    TranslationKey.filterRuleDetectTips.tr,
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: buildRuleList(context, !showAppBar),
          ),
        ],
      ),
    );
    final currentTheme = Theme.of(context);
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Row(
                  children: [
                    Expanded(child: Text(widget.title)),
                    Tooltip(
                      message: TranslationKey.done.tr,
                      child: IconButton(
                        onPressed: () {
                          onConfirmClicked(context);
                        },
                        icon: const Icon(Icons.check),
                      ),
                    ),
                  ],
                ),
                backgroundColor: currentTheme.colorScheme.inversePrimary,
              )
            : null,
        body: body,
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: body,
    );
  }
}
