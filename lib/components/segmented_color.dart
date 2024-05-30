import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SegmentedTextColorContainer extends StatelessWidget {
  final Color segmentedColor;
  final double factor;
  final Widget child;
  final TextStyle defaultTextStyle;

  const SegmentedTextColorContainer({
    super.key,
    required this.segmentedColor,
    required double widthFactor,
    required this.child,
    required this.defaultTextStyle,
  }) : factor = widthFactor > 1 ? 1 : widthFactor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          DefaultTextStyle(
            style: defaultTextStyle,
            child: child,
          ),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return FractionallySizedBox(
                widthFactor: factor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: DefaultTextStyle(
                    style: defaultTextStyle.copyWith(
                      color: segmentedColor,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
