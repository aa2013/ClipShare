import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';

class EnvironmentSelectionCard extends StatelessWidget {
  final bool selected;
  final GestureTapCallback? onTap;
  final Widget icon;
  final Color? backgroundColor;
  final Widget tipContent;
  final Widget tipDesc;

  const EnvironmentSelectionCard({
    super.key,
    required this.selected,
    this.onTap,
    required this.icon,
    this.backgroundColor,
    required this.tipContent,
    required this.tipDesc,
  });

  double get edgeInset => 8;

  final double height = 80;

  @override
  Widget build(BuildContext context) {
    return Card(
      // color: Colors.white,
      elevation: 0,
      margin:
          EdgeInsets.symmetric(vertical: edgeInset, horizontal: edgeInset / 2),
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
                      const SizedBox(
                        height: 5,
                      ),
                      tipDesc,
                    ],
                  ),
                ),
                SizedBox(
                  width: height * 2 / 3,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: 300.ms,
                    curve: Curves.easeIn,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
