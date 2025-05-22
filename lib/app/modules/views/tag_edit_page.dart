import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/views/v_history_tag_hold.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagEditPage extends StatefulWidget {
  final int hisId;

  const TagEditPage(this.hisId, {super.key});

  static void goto(int hisId) {
    var isBigScreen = MediaQuery.of(Get.context!).size.width >= Constants.smallScreenWidth;
    if (isBigScreen || PlatformExt.isDesktop) {
      Get.dialog(
        DynamicSizeWidget(
          child: TagEditPage(hisId),
        ),
      );
    } else {
      Get.to(TagEditPage(hisId));
    }
  }

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  static const tag = "TagEditPage";

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final tagService = Get.find<TagService>();
  final TextEditingController _textController = TextEditingController();
  final List<VHistoryTagHold> _tags = List.empty(growable: true);
  late List<VHistoryTagHold> _origin;
  final List<VHistoryTagHold> _selected = List.empty(growable: true);
  bool saving = false;
  bool exists = false;

  bool get isBigScreen => MediaQuery.of(Get.context!).size.width >= Constants.smallScreenWidth;

  @override
  void initState() {
    super.initState();
    dbService.historyTagDao.listWithHold(widget.hisId).then((lst) {
      _selected.clear();
      _tags.clear();
      _tags.addAll(lst);
      _selected.addAll(lst.where((v) => v.hasTag));
      //原始值，禁止改变
      _origin = List.of(_selected);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarTitle = Row(
      children: [
        Expanded(child: Text(TranslationKey.tagEditPageAppBarTitle.tr)),
        TextButton(
          onPressed: () {
            setState(() {
              saving = true;
            });
            try {
              var originSet = _origin.toSet();
              var selectedSet = _selected.toSet();
              //原始值 - 选择的值，找出被删除的tag
              var willRmSet = originSet.difference(selectedSet);
              //选择的值 - 原始值，找出应增加的tag
              var willAddSet = selectedSet.difference(originSet);

              var willRmList = List<HistoryTag>.empty(growable: true);
              var willAddList = List<HistoryTag>.empty(growable: true);

              Future<int?> link = Future.value(0);

              ///找出所有需要删除的 tag id
              for (var v in willRmSet) {
                var id = widget.hisId;
                link = link.then((value) {
                  //获取原 hisTagId
                  return dbService.historyTagDao.get(id, v.tagName).then((ht) {
                    if (ht == null) return Future.value();
                    willRmList.add(ht);
                    return Future.value();
                  });
                });
              }

              ///生成所有需要添加的 tag
              for (var v in willAddSet) {
                var t = HistoryTag(v.tagName, widget.hisId);
                willAddList.add(t);
              }

              link.then((value) => tagService.removeList(willRmList)).then((value) => tagService.addList(willAddList)).then(
                    (value) => setState(() {
                      saving = false;
                      Navigator.pop(context);
                    }),
                  );
            } catch (e, t) {
              setState(() {
                saving = false;
              });
              Log.debug(tag, e);
              Log.debug(tag, t);
            }
          },
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                )
              : Text(TranslationKey.save.tr),
        ),
      ],
    );
    return RoundedScaffold(
      title: appBarTitle,
      icon: const Icon(Icons.tag),
      child: ListView(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              hintText: TranslationKey.tagEditPageSearchOrCreateTag.tr,
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onChanged: (text) {
              for (var t in _tags) {
                if (t.tagName == text) {
                  setState(() {
                    exists = true;
                  });
                  return;
                }
              }
              setState(() {
                exists = false;
              });
            },
          ),
          _textController.text.isNotEmpty && !exists
              ? TextButton(
                  onPressed: () {
                    var text = _textController.text;
                    var tagHold = VHistoryTagHold(widget.hisId, text, true);
                    _tags.add(tagHold);
                    _selected.add(tagHold);
                    _textController.clear();
                    setState(() {
                      exists = true;
                    });
                  },
                  child: Text(
                    TranslationKey.tagEditPageCrateTagItem.trParams({"tag": _textController.text}),
                  ),
                )
              : const SizedBox.shrink(),
          Column(
            children: [
              for (var item in _tags.where((item) => _textController.text.isEmpty || item.tagName.toLowerCase().contains(_textController.text.toLowerCase())))
                Column(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 5),
                        child: Row(
                          children: [
                            Text(item.tagName),
                            const Expanded(child: SizedBox.shrink()),
                            Checkbox(
                              value: item.hasTag,
                              onChanged: (checked) {
                                if (checked!) {
                                  item.hasTag = true;
                                  _selected.add(item);
                                } else {
                                  item.hasTag = false;
                                  _selected.remove(item);
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
