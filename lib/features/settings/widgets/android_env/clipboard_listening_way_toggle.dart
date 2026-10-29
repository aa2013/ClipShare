import 'package:clipshare/features/settings/extensions/clipboard_env_type_extension.dart';
import 'package:clipshare/features/settings/widgets/card/clipboard_listening_way_setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_header.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/clipboard_listener_way_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';

/// Android 剪贴板监听方式切换。
///
/// 仅 Shizuku / root 特权环境提供隐藏 API 监听，其余模式只能用系统日志方式，
/// 因此不可用时整块收起。切换监听方式会重启剪贴板监听，由调用方在 [onSelected] 中完成。
class ClipboardListeningWayToggle extends StatelessWidget {
  /// 当前工作模式，决定是否展示监听方式切换
  final EnvironmentType workingMode;

  /// 当前生效的监听方式
  final ClipboardListeningWay listeningWay;

  /// 选中监听方式后的回调，由调用方负责持久化并重启监听
  final ValueChanged<ClipboardListeningWay> onSelected;

  /// 监听方式展示顺序：隐藏 API 在左，系统日志在右
  static const List<ClipboardListeningWay> displayOrder = [
    ClipboardListeningWay.hiddenApi,
    ClipboardListeningWay.logs,
  ];

  /// 卡片之间的间隙
  static const double cardSpacing = 3;

  const ClipboardListeningWayToggle({
    super.key,
    required this.workingMode,
    required this.listeningWay,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: workingMode.showListeningWay,
      child: Column(
        children: [
          SettingHeader(
            icon: const Icon(
              Icons.developer_mode,
              size: 17,
            ),
            title: TranslationKey.clipboardListeningWay.tr,
            tips: _buildTips(context),
            padding: const EdgeInsets.only(bottom: 8, left: 8),
          ),
          Row(
            children: [
              for (var i = 0; i < displayOrder.length; i++) _buildWayCard(context, displayOrder[i], i),
            ],
          ),
        ],
      ),
    );
  }

  /// 生成单个监听方式卡片：间隙只落在相邻两张卡片之间，外侧不留白
  Widget _buildWayCard(BuildContext context, ClipboardListeningWay way, int index) {
    return Expanded(
      child: ClipboardListeningWaySettingCard(
        cardMargin: EdgeInsets.only(
          left: index == 0 ? 0 : cardSpacing,
          right: index == displayOrder.length - 1 ? 0 : cardSpacing,
        ),
        icon: way.icon,
        name: way.tr,
        selected: way == listeningWay,
        onTap: () => _confirmSwitch(context, way),
      ),
    );
  }

  /// 切换前二次确认：重启监听期间剪贴板同步会短暂中断
  void _confirmSwitch(BuildContext context, ClipboardListeningWay way) {
    if (way == listeningWay) {
      return;
    }
    dialogManager.tips(
      context,
      text: TranslationKey.clipboardListeningWayToggleConfirmContent.trParams({'way': way.tr}),
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(onPressed: () => onSelected(way)),
      ),
    );
  }

  /// 说明入口：桌面端悬停预览，移动端点击查看完整说明
  Widget _buildTips(BuildContext context) {
    return Tooltip(
      message: TranslationKey.clipboardListeningWayTips.tr,
      child: GestureDetector(
        onTap: () => dialogManager.tips(
          context,
          text: TranslationKey.clipboardListeningWayTipsDetail.tr,
        ),
        child: const MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(
            Icons.info_outline,
            color: Colors.blueGrey,
            size: 15,
          ),
        ),
      ),
    );
  }
}