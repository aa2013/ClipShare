import 'package:flutter/material.dart';

class EnvironmentStatusCard extends StatelessWidget {
  final GestureTapCallback? onTap;
  final Widget icon;
  final Color? backgroundColor;
  final Widget tipContent;
  final Widget tipDesc;
  final Widget? action;

  const EnvironmentStatusCard({
    super.key,
    this.onTap,
    required this.icon,
    this.backgroundColor,
    required this.tipContent,
    required this.tipDesc,
    this.action,
  });

  double get edgeInset => 8;

  final double height = 80;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: edgeInset),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Padding(
          padding: EdgeInsets.all(edgeInset),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                SizedBox(
                  width: height,
                  child: icon,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tipContent,
                      tipDesc,
                    ],
                  ),
                ),
                action ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
