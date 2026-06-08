import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare_clipboard_listener/models/app_info.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip/app_icon.dart';
import 'package:clipshare/app/widgets/clip/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/clip/clip_simple_data_footer.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

///多窗口下一些数据拿不到所以单独写一个
class ClipDataCardCompact extends StatefulWidget {
  final String devName;
  final ClipData clip;
  final void Function(int id, bool isTop) onTopChanged;
  final void Function(int id) onDelete;

  const ClipDataCardCompact({
    super.key,
    required this.clip,
    required this.devName,
    required this.onTopChanged,
    required this.onDelete,
  });

  @override
  State<StatefulWidget> createState() => _ClipDataCardCompactState();
}

class _ClipDataCardCompactState extends State<ClipDataCardCompact> {
  final multiWindowService = Get.find<MultiWindowChannelService>();

  ///右键菜单
  void showMenu(Offset? position, BuildContext context) {
    final clip = widget.clip;
    final menu = ContextMenu(
      entries: [
        MenuItem(
          label: clip.data.top
              ? TranslationKey.cancelTopUp.tr
              : TranslationKey.topUp.tr,
          icon: clip.data.top ? Icons.push_pin : Icons.push_pin_outlined,
          onSelected: () {
            var id = clip.data.id;
            //置顶取反
            var isTop = !clip.data.top;
            widget.onTopChanged.call(id, isTop); // 修改这里
            setState(() {
              clip.data.top = isTop;
            });
          },
        ),
        MenuItem(
          label: TranslationKey.copyContent.tr,
          icon: Icons.copy,
          onSelected: () {
            if (clip.isFile) {
              OpenFile.open(clip.data.content);
              return;
            }
            multiWindowService.copy(0, clip.data.id).then(
                  (args) => Global.showSnackBarSuc(
                    context: context,
                    text: TranslationKey.copySuccess.tr,
                  ),
                );
          },
        ),
        MenuItem(
          label: TranslationKey.delete.tr,
          icon: Icons.delete,
          onSelected: () {
            widget.onDelete.call(clip.data.id);
          },
        ),
      ],
      position: position,
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(8),
    );
    menu.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    var isDouble = false;
    return SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () async {
            if (isDouble) {
              if (clip.isFile) {
                await OpenFile.open(clip.data.content);
                return;
              }
              multiWindowService.copy(0, clip.data.id).then(
                    (args) => Global.showSnackBarSuc(
                      context: context,
                      text: TranslationKey.copySuccess.tr,
                    ),
                  );
              isDouble = false;
            } else {
              isDouble = true;
              Future.delayed(300.ms, () {
                isDouble = false;
              });
            }
          },
          onSecondaryTapDown: (details) {
            showMenu(details.globalPosition - const Offset(0, 70), context);
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (clip.data.source != null)
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: AppIcon(appId: clip.data.source!),
                      ),
                    RoundedChip(
                      avatar: const Icon(Icons.devices_rounded),
                      backgroundColor: const Color(0x1a000000),
                      label: Text(
                        widget.devName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipSimpleDataContent(
                    clip: clip,
                    imgOnlyView: true,
                    imgSingleView: true,
                  ),
                ),
                const SizedBox(height: 1),
                ClipSimpleDataFooter(clip: clip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
