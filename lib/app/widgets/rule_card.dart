import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RuleCard extends StatelessWidget {
  final RuleItem rule;
  final int? orderedIndex;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool>? onSelectedChanged;
  final GestureTapCallback onTap;
  final GestureLongPressCallback? onLongPress;
  final bool selectMode;
  final bool selected;

  const RuleCard({
    super.key,
    required this.rule,
    required this.onEnabledChanged,
    required this.onTap,
    this.onLongPress,
    this.selectMode = false,
    this.selected = false,
    this.onSelectedChanged,
    this.orderedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                Row(
                  children: [
                    Visibility(
                      visible: selectMode,
                      child: Checkbox(
                        value: selected,
                        onChanged: (v) {
                          onSelectedChanged?.call(v ?? false);
                        },
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name),
                      const SizedBox(height: 2),
                      Wrap(
                        children: [
                          Text(
                            "${TranslationKey.source.tr}: ",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          for (var appId in rule.sources)
                            Container(
                              margin: const EdgeInsets.only(right: 2, bottom: 2),
                              child: AppIcon(
                                appId: appId,
                                iconSize: Constants.appIconSize,
                              ),
                            ),
                          if (rule.sources.isEmpty)
                            Text(
                              TranslationKey.all.tr,
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: rule.enabled,
                        padding: EdgeInsets.zero,
                        onChanged: selectMode ? null : (checked) => onEnabledChanged(checked),
                      ),
                    ),
                    if (orderedIndex != null)
                      ReorderableDragStartListener(
                        index: orderedIndex!,
                        child: selectMode
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () {},
                                tooltip: '拖拽排序',
                                icon: const Icon(Icons.drag_indicator),
                                padding: EdgeInsets.zero,
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
