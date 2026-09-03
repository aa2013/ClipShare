import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/history_data_extension.dart';
import 'package:clipshare/core/providers/device/device_provider.dart';
import 'package:clipshare/core/providers/tag/tag_provider.dart';
import 'package:clipshare/core/utils/consumer_wrapper.dart';
import 'package:clipshare/features/history/widgets/copy_icon_button.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_icon.dart';
import 'history_tag_row.dart';

///历史记录中的卡片显示的额外信息部分，如时间，大小等
class HistoryCardHeader extends ConsumerWidget {
  final History history;
  final bool showOriginData;
  final VoidCallback? onOriginButtonClicked;

  const HistoryCardHeader({
    super.key,
    required this.history,
    this.showOriginData = false,
    this.onOriginButtonClicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        //剪贴板来源
        if (history.source != null)
          Container(
            margin: const EdgeInsets.only(right: 5),
            child: AppIcon(appId: history.source!),
          ),
        //来源设备
        RoundedChip(
          avatar: const Icon(Icons.devices_rounded),
          label: consumerWrapper((context, ref) => _buildDeviceChip(history, context, ref)),
        ),
        //标签
        Expanded(
          child: ClipRRect(
            child: consumerWrapper((context, ref) => _buildTagsRow(history, context, ref)),
          ),
        ),
        Visibility(
          visible: history.extracted != null,
          child: IconButton(
            onPressed: onOriginButtonClicked,
            icon: Icon(
              showOriginData ? Icons.zoom_in_map : Icons.zoom_out_map,
              size: 16,
              color: Colors.blueGrey,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: showOriginData ? TranslationKey.displayExtractedContent.tr : TranslationKey.displayOriginContent.tr,
          ),
        ),
        Visibility(
          visible: history.canCopy,
          child: CopyIconButton(
            onClick: () {
              history.copyContent(
                context: context,
                showFeedback: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildDeviceChip(History history, BuildContext context, WidgetRef ref) {
  final deviceState = ref.watch(deviceProvider);
  final devId = history.devId;
  final devName = deviceState.requireValue.getName(devId);
  return Text(
    devName,
    style: const TextStyle(fontSize: 12),
  );
}

Widget _buildTagsRow(History history, BuildContext context, WidgetRef ref) {
  ref.watch(tagProvider);
  return HistoryTagRow(hisId: history.id);
}
