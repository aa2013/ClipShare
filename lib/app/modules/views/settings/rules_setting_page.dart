import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule.dart';
import 'package:clipshare/app/modules/views/settings/rule_item.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:clipshare/app/widgets/settings/rule/rule_import_preview.dart';
import 'package:clipshare/app/widgets/settings/rule/rule_import_type.dart';
import 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timer_snackbar/timer_snackbar.dart';

class RuleSettingPage extends StatefulWidget {
  final bool Function(Rule submit) onAdd;
  final Widget Function(
    Rule? initData,
    Function(Rule) onChange,
  )
  editDialogLayout;
  final void Function(List<Rule> result) confirm;
  final List<Rule> initData;
  final String title;
  final Widget Function(int i, Rule rule, void Function(int i, Rule rule) remove) action;

  const RuleSettingPage({
    super.key,
    required this.onAdd,
    required this.confirm,
    required this.title,
    required this.editDialogLayout,
    required this.initData,
    required this.action,
  });

  @override
  State<StatefulWidget> createState() {
    return _RuleSettingPageState();
  }
}

class _RuleSettingPageState extends State<RuleSettingPage> {
  final List<Rule> _list = List.empty(growable: true);
  Rule? _addData;
  Rule? _editData;
  bool selectionMode = false;
  final Set<Rule> selectedList = {};
  static String tag = "RuleSettingPage";

  @override
  void initState() {
    super.initState();
    _list.addAll(widget.initData);
  }

  void remove(int i, Rule rule) {
    _list.removeWhere((item) => item.name == rule.name);
    setState(() {});
    timerSnackbar(
      scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
      contentText: TranslationKey.deleteSuccess.tr,
      buttonLabel: TranslationKey.revoke.tr,
      margin: null,
      second: 5,
      onActionTap: () {
        _list.insert(i, rule);
        setState(() {});
      },
      afterTimeExecute: () {},
    );
  }

  bool get isSmallScreen => MediaQuery.of(Get.context!).size.width <= Constants.smallScreenWidth;

  void showImportPreviewDialog(List<Rule> rules) {
    Global.showDialog(
      context,
      AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            const Icon(Icons.add),
            const SizedBox(
              width: 10,
            ),
            Text(
              TranslationKey.importRules.tr,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: RuleImportPreview(
          data: rules,
          onCancel: () {
            //关闭自身
            Get.back();
          },
          onConfirm: (selected) {
            final Set<Rule> importData = {};
            importData.addAll(selected);
            for (var item in _list) {
              importData.remove(item);
            }
            _list.addAll(importData);
            setState(() {});
            Global.showSnackBarSuc(
              scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
              text: TranslationKey.importRulesSuccess.trParams({"length": importData.length.toString()}),
            );
            //导入成功关闭自身
            Get.back();
            //关闭导入类型选择弹窗
            Get.back();
          },
        ),
      ),
    );
  }

  void onUrlTypeClicked() {
    Global.showDialog(
      context,
      TextEditDialog(
        title: TranslationKey.importFromNet.tr,
        labelText: "url",
        verify: (url) => url.isURL,
        errorText: TranslationKey.urlFormatErrorText.tr,
        initStr: "",
        okText: TranslationKey.fetch.tr,
        onOk: (url) async {
          bool cancel = false;
          bool closeLoading = false;
          Global.showLoadingDialog(
            context: Get.context!,
            loadingText: TranslationKey.fetchingData.tr,
            showCancel: true,
            onCancel: () {
              closeLoading = true;
              cancel = true;
            },
          );
          try {
            final resp = await http.get(Uri.parse(url));
            //关闭加载弹窗
            if (!closeLoading && !cancel) {
              closeLoading = true;
              Get.back();
            }
            if (resp.statusCode != 200) {
              Global.showTipsDialog(
                context: context,
                text: resp.statusCode.toString(),
                title: TranslationKey.failedToLoad.tr,
              );
            } else {
              final rules = Rule.fromJson(
                (jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>).cast<Map<String, dynamic>>(),
              );
              showImportPreviewDialog(rules);
            }
          } on Exception catch (err, stack) {
            print(err);
            //关闭加载弹窗
            if (!closeLoading && !cancel) {
              closeLoading = true;
              Get.back();
              return;
            }
            Global.showTipsDialog(
              context: context,
              title: TranslationKey.failedToLoad.tr,
              text: err.toString(),
            );
          }
        },
      ),
    );
  }

  Future<void> onLocalFileTypeClicked() async {
    var result = await FilePicker.platform.pickFiles(
      lockParentWindow: true,
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: List.unmodifiable(["json"]),
    );
    if (result == null) {
      return;
    }
    var platformFile = result.files[0];
    if (platformFile.path == null) {
      Global.showSnackBarWarn(
        text: TranslationKey.noSuchFile.tr,
        scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
      );
    }
    final file = File(platformFile.path!);
    file
        .readAsBytes()
        .then((bytes) {
          final content = utf8.decode(bytes);
          final rules = Rule.fromJson(
            (jsonDecode(content) as List<dynamic>).cast<Map<String, dynamic>>(),
          );
          showImportPreviewDialog(rules);
        })
        .catchError((err) {
          Log.error(tag, err);
          Global.showSnackBarWarn(
            text: TranslationKey.failedToReadFile.tr,
            scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
          );
        });
  }

  void showEditDialog(int? idx, Rule? initData) {
    if (initData != null) {
      _editData = initData;
    }
    late DialogController outDialog;
    outDialog = Global.showDialog(
      context,
      AlertDialog(
        title: Text(TranslationKey.addRule.tr),
        content: widget.editDialogLayout.call(initData, (data) {
          if (idx == null) {
            _addData = data;
          } else {
            _editData = data;
          }
        }),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  final dialog = Global.showDialog(
                    context,
                    AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.add),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            TranslationKey.importRule.tr,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      content: RuleImportType(
                        onUrlTypeClicked: onUrlTypeClicked,
                        onLocalFileTypeClicked: onLocalFileTypeClicked,
                      ),
                    ),
                  );
                  dialog.future.then((v) => outDialog.close());
                },
                label: Text(TranslationKey.import.tr),
                icon: const Icon(Icons.add),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _addData = null;
                        _editData = null;
                        outDialog.close();
                      },
                      child: Text(TranslationKey.dialogCancelText.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        final data = idx == null ? _addData! : _editData!;
                        var res = widget.onAdd(data);
                        if (!res) return;
                        outDialog.close();
                        if (idx == null) {
                          _list.add(data);
                        } else {
                          _list[idx] = data;
                        }
                        _addData = null;
                        _editData = null;
                        setState(() {});
                      },
                      child: Text(idx == null ? TranslationKey.add.tr : TranslationKey.modify.tr),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final mainScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: mainScaffoldMessengerKey,
      child: RoundedScaffold(
        title: Row(
          children: [
            Expanded(child: Text(widget.title)),
            Visibility(
              visible: selectionMode && selectedList.isNotEmpty,
              child: Tooltip(
                message: TranslationKey.output.tr,
                child: IconButton(
                  onPressed: () {
                    FileUtil.exportFile(
                          TranslationKey.outputRule.tr,
                          "export_rules.json",
                          jsonEncode(selectedList.toList()),
                        )
                        .then((outputPath) {
                          if (outputPath != null) {
                            Global.showSnackBarSuc(
                              text: TranslationKey.outputSuccess.tr,
                              scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
                            );
                          }
                        })
                        .catchError((err) {
                          Global.showSnackBarWarn(
                            text: "${TranslationKey.outputFailed.tr}: $err",
                            scaffoldMessengerState: mainScaffoldMessengerKey.currentState!,
                          );
                        });
                  },
                  icon: const Icon(Icons.output),
                ),
              ),
            ),
            Tooltip(
              message: TranslationKey.save.tr,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.confirm.call(_list);
                },
                icon: const Icon(Icons.save),
              ),
            ),
            Visibility(
              visible: !isSmallScreen,
              child: Tooltip(
                message: TranslationKey.dialogCancelText.tr,
                child: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
        icon: const Icon(Icons.window),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Tooltip(
              message: selectionMode ? TranslationKey.exitSelectionMode.tr : TranslationKey.addRule.tr,
              child: FloatingActionButton(
                onPressed: () {
                  if (selectionMode) {
                    setState(() {
                      selectionMode = false;
                      selectedList.clear();
                    });
                  } else {
                    showEditDialog(null, null);
                  }
                },
                child: Icon(selectionMode ? Icons.close : Icons.add), // 可以选择其他图标
              ),
            ),
            Visibility(
              visible: selectionMode,
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                child: Tooltip(
                  message: selectedList.length == _list.length ? TranslationKey.cancelSelectAll.tr : TranslationKey.selectAll.tr,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (selectedList.length == _list.length) {
                        selectedList.clear();
                      } else {
                        selectedList.addAll(_list);
                      }
                      setState(() {});
                    },
                    child: Icon(
                      selectedList.length == _list.length ? Icons.deselect : Icons.checklist,
                    ), // 可以选择其他图标
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Visibility(
          visible: _list.isEmpty,
          replacement: Padding(
            padding: const EdgeInsets.all(5),
            child: ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, i) {
                final rule = _list[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  child: RuleItem(
                    rule: rule,
                    selectionMode: selectionMode,
                    borderRadius: BorderRadius.circular(8),
                    selected: selectedList.contains(rule),
                    onTap: () {
                      if (selectionMode) {
                        if (selectedList.contains(rule)) {
                          selectedList.remove(rule);
                        } else {
                          selectedList.add(rule);
                        }
                        setState(() {});
                      } else {
                        showEditDialog(i, rule);
                      }
                    },
                    action: widget.action.call(i, rule, remove),
                    onLongPress: () {
                      if (!selectionMode) {
                        setState(() {
                          selectionMode = true;
                          selectedList.add(rule);
                        });
                      }
                    },
                    onSelectionChange: (selected) {
                      if (selected) {
                        selectedList.add(rule);
                      } else {
                        selectedList.remove(rule);
                      }
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
          child: EmptyContent(),
        ),
      ),
    );
  }
}
