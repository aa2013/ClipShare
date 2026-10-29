import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/widgets/segmented_color.dart';
import 'package:flutter/material.dart';

/// 传输进度条：进度条上覆盖一行前景背景双色文字。
/// [leftTexts] 展示在进度起点侧（大小、速度、剩余时间），
/// [rightTexts] 展示在进度终点侧（百分比、日期）。
class TransferProgressBar extends StatelessWidget {
  static const _barHeight = 20.0;

  /// 进度因子（0~1）
  final double factor;

  /// 失败态：进度条变红
  final bool error;

  final List<String> leftTexts;
  final List<String> rightTexts;

  const TransferProgressBar({
    super.key,
    required this.factor,
    this.error = false,
    this.leftTexts = const [],
    this.rightTexts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final value = factor.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: 300.ms,
      builder: (context, animated, _) {
        return Stack(
          children: [
            LinearProgressIndicator(
              value: animated,
              minHeight: _barHeight,
              color: error ? Colors.red : null,
              borderRadius: BorderRadius.circular(_barHeight / 2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SizedBox(
                height: _barHeight,
                child: SegmentedTextColorContainer(
                  segmentedColor: Colors.white,
                  widthFactor: animated,
                  defaultTextStyle: const TextStyle(color: Colors.black),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextGroup(leftTexts),
                      _buildTextGroup(rightTexts),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 组内文本以竖线分隔，超出时整体省略
  Widget _buildTextGroup(List<String> texts) {
    final children = <Widget>[];
    for (var i = 0; i < texts.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            height: 10,
            margin: const EdgeInsets.only(left: 5, right: 5),
            color: Colors.grey,
          ),
        );
      }
      children.add(Text(texts[i], maxLines: 1, overflow: TextOverflow.ellipsis));
    }
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
