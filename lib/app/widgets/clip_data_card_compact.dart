import 'package:clipshare_clipboard_listener/models/app_info.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:clipshare/app/widgets/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/clip_simple_data_extra_info.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

///多窗口下一些数据拿不到所以单独写一个
class ClipDataCardCompact extends StatelessWidget {
  final String devName;
  final ClipData _clip;

  final multiWindowChannelService = Get.find<MultiWindowChannelService>();

  ClipDataCardCompact({
    super.key,
    required ClipData clip,
    required this.devName,
  }) : _clip = clip;

  @override
  Widget build(BuildContext context) {
    var isDouble = false;
    return SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () async {
            if (isDouble) {
              if (_clip.isFile) {
                await OpenFile.open(_clip.data.content);
                return;
              }
              multiWindowChannelService.copy(0, _clip.data.id).then(
                    (args) => Global.showSnackBarSuc(
                      context: context,
                      text: TranslationKey.copySuccess.tr,
                    ),
                  );
              isDouble = false;
            } else {
              isDouble = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                isDouble = false;
              });
            }
          },
          onSecondaryTap: () {
            print("右键");
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_clip.data.source != null)
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: AppIcon(appId: _clip.data.source!),
                      ),
                    RoundedChip(
                      avatar: const Icon(Icons.devices_rounded),
                      backgroundColor: const Color(0x1a000000),
                      label: Text(
                        devName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ClipSimpleDataContent(
                    clip: _clip,
                    imgOnlyView: true,
                    imgSingleView: true,
                  ),
                ),
                ClipSimpleDataExtraInfo(clip: _clip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
