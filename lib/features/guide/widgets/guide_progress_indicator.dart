import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';

/// 引导页底部的步骤指示器。
///
/// 当前步骤以加宽的胶囊展示，已走过的步骤保持高亮。
class GuideProgressIndicator extends StatelessWidget {
  /// 步骤总数。
  final int total;

  /// 当前步骤下标。
  final int current;

  /// 普通指示点的直径。
  static const double _dotSize = 10;

  /// 普通指示点的占位高度。
  static const double _dotSlotHeight = 16;

  /// 当前步骤指示条的宽度。
  static const double _activeWidth = 36;

  /// 当前步骤指示条的宽度。
  static const double _activeDotWidth = 30;

  /// 指示点切换动画时长。
  static const int _animationMilliseconds = 200;

  const GuideProgressIndicator({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final duration = _animationMilliseconds.ms;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            width: i == current ? _activeWidth : _dotSlotHeight,
            height: _dotSlotHeight,
            duration: duration,
            child: Center(
              child: AnimatedContainer(
                width: i == current ? _activeDotWidth : _dotSize,
                height: _dotSize,
                duration: duration,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: i <= current ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}