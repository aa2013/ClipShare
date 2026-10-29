import 'package:flutter/material.dart';

class ClipboardListeningWaySettingCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String name;
  final EdgeInsets? cardMargin;
  final EdgeInsets? containerMargin;
  final GestureTapCallback? onTap;

  const ClipboardListeningWaySettingCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.name,
    this.cardMargin,
    this.containerMargin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: cardMargin,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Stack(
          children: [
            Container(
              margin: containerMargin ?? const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.blue : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: TextStyle(
                      color: selected ? Colors.blue : null,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                right: 5,
                bottom: 5,
                child: Icon(
                  Icons.check_circle_outline_outlined,
                  color: Colors.blue,
                  size: 17,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
