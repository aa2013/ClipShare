import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

/// 多选浮动按钮动作定义。
///
/// 使用可空回调表示动作禁用态，保持主窗体与历史弹窗的可用性提示一致。
class ClipMultiSelectionFabAction {
  final VoidCallback? onPressed;
  final String tooltip;
  final Widget child;

  const ClipMultiSelectionFabAction({
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });
}

/// 多选模式通用 FAB。
///
/// 统一渲染计数徽标、回到顶部按钮以及扇形动作区，
/// 让不同列表只关心自身动作与滚动回调。
class ClipMultiSelectionFab extends StatelessWidget {
  final bool selectMode;
  final int selectedCount;
  final int totalCount;
  final bool showBackToTopButton;
  final double distance;
  final VoidCallback onBackToTop;
  final List<ClipMultiSelectionFabAction> actions;

  const ClipMultiSelectionFab({
    super.key,
    required this.selectMode,
    required this.distance,
    required this.selectedCount,
    required this.totalCount,
    required this.showBackToTopButton,
    required this.onBackToTop,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    const fabSize = ExpandableFabSize.regular;
    final colorScheme = Theme.of(context).colorScheme;
    final children = <Widget>[
      Visibility(
        visible: selectMode,
        child: Positioned(
          right: 85,
          bottom: 15,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$selectedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Visibility(
        visible: showBackToTopButton,
        child: AnimatedPositioned(
          right: 15,
          bottom: selectMode ? 85 : 15,
          duration: 300.ms,
          child: FloatingActionButton(
            onPressed: onBackToTop,
            child: const Icon(Icons.arrow_upward),
          ),
        ),
      ),
      Visibility(
        visible: selectMode,
        child: ExpandableFab(
          distance: distance,
          type: ExpandableFabType.fan,
          overlayStyle: const ExpandableFabOverlayStyle(blur: 8),
          openButtonBuilder: RotateFloatingActionButtonBuilder(
            fabSize: fabSize,
            child: const Icon(Icons.menu),
          ),
          closeButtonBuilder: DefaultFloatingActionButtonBuilder(
            fabSize: fabSize,
            child: const Icon(Icons.close),
          ),
          children: actions.map(_buildActionButton).toList(growable: false),
        ),
      ),
    ];
    return SizedBox.expand(
      child: Stack(children: children),
    );
  }

  /// 禁用态统一使用灰色背景，避免不同页面的多选操作视觉反馈不一致。
  FloatingActionButton _buildActionButton(ClipMultiSelectionFabAction action) {
    final bgColor = action.onPressed == null ? Colors.grey[400] : null;
    return FloatingActionButton(
      onPressed: action.onPressed,
      tooltip: action.tooltip,
      backgroundColor: bgColor,
      child: action.child,
    );
  }
}
