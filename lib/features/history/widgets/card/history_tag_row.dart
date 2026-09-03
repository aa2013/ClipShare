import 'package:clipshare/core/providers/tag/tag_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/base/condition_widget.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryTagRow extends ConsumerWidget {
  final int hisId;
  final Color? clipBgColor;
  final bool? showAddIcon;

  const HistoryTagRow({
    super.key,
    required this.hisId,
    this.clipBgColor = const Color(0x1a000000),
    this.showAddIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.read(tagProvider).value;
    final tags = tagState?.getTagList(hisId) ?? const <String>{};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var tag in tags)
            Container(
              margin: const EdgeInsets.only(left: 5),
              child: RoundedChip(
                avatar: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ConditionWidget(
            visible: showAddIcon == true,
            child: const SizedBox(width: 5),
          ),
          ConditionWidget(
            visible: showAddIcon == true,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                // todo
                // TagEditPage.goto(hisId);
              },
              icon: Row(
                children: [
                  Text(TranslationKey.tag.tr),
                  const Icon(Icons.add, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
