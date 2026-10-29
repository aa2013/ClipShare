import 'package:clipshare/core/settings/data_cleanup/data_cleanup_freq.dart';
import 'package:clipshare/features/data_cleanup/enums/week_day.dart';
import 'package:clipshare/features/data_cleanup/providers/data_cleanup_page_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/widgets/base/radio_group.dart';
import 'package:clipshare/shared/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/shared/widgets/dialogs/single_select_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 自动清理配置卡片：开关、频率、执行时间与下次执行时间预览。
class AutoCleanConfigCard extends ConsumerStatefulWidget {
  const AutoCleanConfigCard({super.key});

  @override
  ConsumerState<AutoCleanConfigCard> createState() => _AutoCleanConfigCardState();
}

class _AutoCleanConfigCardState extends ConsumerState<AutoCleanConfigCard> {
  /// cron 表达式输入控制器
  late final TextEditingController cronInputCtl;

  @override
  void initState() {
    super.initState();
    final cronInput = ref.read(dataCleanupPageProvider).cronInput;
    cronInputCtl = TextEditingController(text: cronInput);
  }

  @override
  void dispose() {
    cronInputCtl.dispose();
    super.dispose();
  }

  /// 选择一周的某一天
  void _showWeekDaySelectDialog() {
    final state = ref.read(dataCleanupPageProvider);
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    late final DialogController dialog;
    dialog = SingleSelectDialog.show<int>(
      context: context,
      selections: WeekDay.values.map((w) => RadioData(value: w.value, label: w.label)).toList(),
      title: Text(TranslationKey.selectWeekDay.tr),
      defaultValue: state.selectedWeekDay?.value ?? WeekDay.monday.value,
      onSelected: (selected) {
        // 延迟关闭，保证单选 UI 先完成状态更新
        Future.delayed(100.ms).then((_) {
          notifier.setWeekDay(WeekDay.parse(selected));
          dialog.close();
        });
      },
    );
  }

  /// 选择执行时间（时分，24 小时制）
  Future<void> _showTimeSelectDialog() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    notifier.setTime(
      hour: picked.hour.toString().padLeft(2, '0'),
      minute: picked.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataCleanupPageProvider);
    final notifier = ref.read(dataCleanupPageProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const sectionColor = Colors.blueGrey;
    final chipSide = BorderSide(color: colorScheme.outlineVariant);
    const chipLabelStyle = TextStyle(fontSize: 12);
    final freqs = [DataCleanupFreq.day, DataCleanupFreq.week, DataCleanupFreq.cron];
    final labels = [TranslationKey.daily.tr, TranslationKey.weekly.tr, 'Cron'];

    return Card(
      color: theme.cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //region 标题 + 自动清理开关
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: sectionColor, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      TranslationKey.autoCleanConfigTitle.tr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sectionColor),
                    ),
                  ],
                ),
                Switch(
                  value: state.autoClean,
                  onChanged: (checked) {
                    HapticFeedback.mediumImpact();
                    notifier.setAutoClean(checked);
                  },
                ),
              ],
            ),

            //endregion

            //region 清理频率
            Row(
              children: [
                const Icon(Icons.equalizer_outlined, color: sectionColor, size: 16),
                const SizedBox(width: 2),
                Text(TranslationKey.autoCleanFrequency.tr, style: const TextStyle(color: sectionColor)),
              ],
            ),
            const SizedBox(height: 6),
            TinySegmentedControl.fromStrings(
              options: labels,
              onSelected: (int index) {
                notifier.setFrequency(freqs[index]);
              },
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.onPrimaryContainer,
              selectedBackgroundColor: colorScheme.primaryContainer,
              unselectedColor: colorScheme.onSurfaceVariant,
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            ),
            const SizedBox(height: 4),

            //endregion

            //region 执行时间
            Row(
              children: [
                const Icon(Icons.timer, color: sectionColor, size: 16),
                const SizedBox(width: 2),
                Text(TranslationKey.execTime.tr, style: const TextStyle(color: sectionColor)),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Visibility(
                visible: state.frequency == DataCleanupFreq.cron,
                replacement: Row(
                  children: [
                    Visibility(
                      visible: state.frequency == DataCleanupFreq.week,
                      child: RawChip(
                        label: Text(state.selectedWeekDay?.label ?? WeekDay.monday.label),
                        labelStyle: chipLabelStyle,
                        side: chipSide,
                        onPressed: _showWeekDaySelectDialog,
                        visualDensity: const VisualDensity(
                          horizontal: VisualDensity.minimumDensity,
                          vertical: VisualDensity.minimumDensity,
                        ),
                        labelPadding: EdgeInsets.zero,
                      ),
                    ),
                    Visibility(
                      visible: state.frequency == DataCleanupFreq.week,
                      child: const SizedBox(width: 10),
                    ),
                    RawChip(
                      label: Text('${state.selectedHour} h : ${state.selectedMinute} min'),
                      labelStyle: chipLabelStyle,
                      side: chipSide,
                      onPressed: _showTimeSelectDialog,
                      visualDensity: const VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity,
                      ),
                      labelPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
                child: TextField(
                  controller: cronInputCtl,
                  decoration: InputDecoration(
                    label: Text('${TranslationKey.pleaseInput.tr} UnixCron'),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.timer, color: sectionColor),
                  ),
                  onChanged: (v) {
                    notifier.updateCronInput(v);
                  },
                ),
              ),
            ),
            Visibility(
              visible: state.nextExecTime != null,
              replacement: Container(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          TranslationKey.errorCronTips.tr,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(
                        TranslationKey.nextExecTime.tr,
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                      Text(
                        state.nextExecTime?.format() ?? '',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //endregion

            //region 操作按钮
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                notifier.saveAutoCleanConfig(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 16),
                  const SizedBox(width: 5),
                  Text(TranslationKey.saveAutoCleanConfig.tr),
                ],
              ),
            ),

            //endregion
          ],
        ),
      ),
    );
  }
}
