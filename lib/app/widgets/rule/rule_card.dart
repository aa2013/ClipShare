import 'package:clipshare/app/data/enums/rule/rule_trigger.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_item.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/app_icon.dart';
import 'package:flutter/material.dart';

class RuleCard extends StatelessWidget {
  final RuleItem rule;
  final int? orderedIndex;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool>? onSelectedChanged;
  final GestureTapCallback onTap;
  final GestureLongPressCallback? onLongPress;
  final bool selectMode;
  final bool disabledDrag;
  final bool selected;
  final bool isActive;

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
    this.isActive = false,
    this.disabledDrag = false,
  });

  static const _activeStyle = TextStyle(
    color: Colors.blueGrey,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.tag;
    TranslationKey tooltip = TranslationKey.unknown;
    switch (rule.trigger) {
      case RuleTrigger.onCopy:
        icon = Icons.text_snippet_outlined;
        tooltip = TranslationKey.triggerOnCopy;
        break;
      case RuleTrigger.onNotification:
        icon = Icons.notifications_active_outlined;
        tooltip = TranslationKey.triggerOnNotification;
        break;
      case RuleTrigger.onSms:
        icon = Icons.sms_outlined;
        tooltip = TranslationKey.triggerOnSms;
        break;
    }
    return SizedBox(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
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
                      Row(
                        children: [
                          Tooltip(
                            message: tooltip.tr,
                            child: Icon(
                              icon,
                              size: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rule.name,
                            style: isActive ? _activeStyle : null,
                          ),
                        ],
                      ),
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
                        child: Visibility(
                          visible: selectMode,
                          replacement: IconButton(
                            mouseCursor: disabledDrag ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                            onPressed: disabledDrag ? null : () {},
                            tooltip: disabledDrag
                                ? TranslationKey.ruleCardDragDisabledTooltip.tr
                                : TranslationKey.ruleCardDragTooltip.tr,
                            icon: const Icon(Icons.drag_indicator),
                            padding: EdgeInsets.zero,
                          ),
                          child: const SizedBox.shrink(),
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
