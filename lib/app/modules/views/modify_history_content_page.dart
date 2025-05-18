import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModifyHistoryContentPage extends StatefulWidget {
  final History data;
  final void Function(bool didUpdate, String? newData) onDone;

  const ModifyHistoryContentPage({
    super.key,
    required this.data,
    required this.onDone,
  });

  @override
  State<StatefulWidget> createState() {
    return _ModifyHistoryContentPageState();
  }
}

class _ModifyHistoryContentPageState extends State<ModifyHistoryContentPage> {
  final editController = TextEditingController();
  late String originData;

  bool didUpdate = false;

  @override
  void initState() {
    super.initState();
    originData = widget.data.content;
    editController.text = widget.data.content;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !didUpdate,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        Global.showTipsDialog(
          context: context,
          text: TranslationKey.unsavedTips.tr,
          showCancel: true,
          onOk: () {
            Get.back();
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Expanded(child: Text(TranslationKey.modifyContent.tr)),
              Tooltip(
                message: TranslationKey.done.tr,
                child: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    if (didUpdate) {
                      Global.showTipsDialog(
                        context: context,
                        text: TranslationKey.confirmModifyContent.tr,
                        showCancel: true,
                        showNeutral: true,
                        neutralText: TranslationKey.modifyContentConfirmExitAndNoSave.tr,
                        onOk: () {
                          widget.onDone(didUpdate, editController.text);
                          Get.back();
                        },
                        onNeutral: () {
                          Get.back();
                        },
                      );
                    } else {
                      widget.onDone(didUpdate, null);
                      Get.back();
                    }
                  },
                ),
              )
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  textAlignVertical: TextAlignVertical.top,
                  textAlign: TextAlign.left,
                  controller: editController,
                  onChanged: (_) {
                    setState(() {
                      didUpdate = editController.text != originData;
                    });
                  },
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
