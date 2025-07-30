import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/blacklist_item.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/dialog/black_list_add_rule_dialog.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlackListPage extends StatefulWidget {
  final void Function()? onDone;

  const BlackListPage({
    super.key,
    this.onDone,
  });

  @override
  State<StatefulWidget> createState() => _BlackListPageState();
}

class _BlackListPageState extends State<BlackListPage> {
  final appIconSize = 17.0;
  final blacklist = <BlackListRule>[].obs;
  final appConfig = Get.find<ConfigService>();
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

  @override
  void initState() {
    super.initState();
    blacklist.value = List.from(appConfig.blackList);
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingHeader(
            title: TranslationKey.ruleList.tr,
            icon: const Icon(
              Icons.list_alt_sharp,
              color: Colors.blueGrey,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.dialog(
              BlackListAddRuleDialog(
                onDone: (data) {
                  onRuleDialogConfirm(-1, data, context);
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

  void onRuleDialogConfirm(int index, BlackListRule data, BuildContext context) {
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
      blacklist.add(data);
    } else {
      blacklist[index] = data;
    }
    Get.back();
  }

  void onConfirmClicked(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    appConfig.setBlacklist(blacklist);
    Global.showSnackBarSuc(text: TranslationKey.saveSuccess.tr, context: context);
    Get.back();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final allContent = Text(
      TranslationKey.all.tr,
      style: const TextStyle(color: Colors.blueGrey),
    );
    final appConfig = Get.find<ConfigService>();
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
                        Text(TranslationKey.enableBlackList.tr),
                        const SizedBox(height: 5),
                        Text(
                          TranslationKey.enableBlackListTips.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Switch(
                      value: appConfig.enableBlackList,
                      onChanged: (enabled) {
                        appConfig.setEnableBlackList(enabled);
                      },
                    ),
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
                    TranslationKey.blacklistDetectTips.tr,
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
            child: Column(
              children: [
                buildHeader(context),
                Expanded(
                  child: Obx(
                    () => Visibility(
                      visible: blacklist.isEmpty,
                      replacement: Obx(
                        () {
                          final length = blacklist.length;
                          return SingleChildScrollView(
                            child: Column(
                              children: List.generate(blacklist.length, (i) {
                                final item = blacklist[i];
                                final borderRadius = length == 1
                                    ? _allBorder
                                    : i == 0
                                    ? _topBorder
                                    : _bottomBorder;
                                return SettingCard<BlackListRule>(
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
                                          message: item.enable ? TranslationKey.disable.tr : TranslationKey.enable.tr,
                                          child: Checkbox(
                                            value: value.enable,
                                            onChanged: (v) {
                                              blacklist[i] = item.copyWith(enable: v);
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
                                                  blacklist.removeAt(i);
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
                                      BlackListAddRuleDialog(
                                        data: blacklist[i],
                                        onDone: (data) {
                                          onRuleDialogConfirm(i, data, context);
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
                Container(
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: TextButton(
                    onPressed: () => onConfirmClicked(context),
                    child: Text(TranslationKey.confirm.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final showAppBar = appConfig.isSmallScreen;
    final currentTheme = Theme.of(context);
    if (showAppBar) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(TranslationKey.blacklistRules.tr),
                    ),
                    IconButton(
                      onPressed: () {
                        onConfirmClicked(context);
                      },
                      icon: const Icon(Icons.check),
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
