import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  final String? description;
  final Color? descriptionTextColor;
  final Widget? icon;
  final double size;
  final bool showText;

  const EmptyContent({
    super.key,
    this.icon,
    this.description,
    this.descriptionTextColor,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child:
              icon ??
              Image.asset(
                emptyPngPath,
                width: size,
                height: size,
              ),
        ),
        if (showText)
          Text(
            description ?? TranslationKey.emptyData.tr,
            style: TextStyle(color: descriptionTextColor ?? Colors.grey),
          ),
      ],
    );
  }
}
