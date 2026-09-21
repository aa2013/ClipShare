import 'package:flutter/material.dart';

class SettingHeader<T> extends StatelessWidget {
  final String title;
  final Icon icon;
  final EdgeInsets? padding;
  final Widget? tips;

  const SettingHeader({
    super.key,
    required this.icon,
    required this.title,
    this.padding,
    this.tips,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            icon,
            const SizedBox(width: 5),
            Text(title),
            if (tips != null) tips!,
          ],
        ),
      ),
    );
  }
}
