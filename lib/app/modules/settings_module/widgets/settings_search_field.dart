import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsSearchField extends StatelessWidget {
  final TextEditingController controller;

  const SettingsSearchField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      decoration: noneBorderInputDecoration.copyWith(
        hintText: '搜索设置...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: TranslationKey.clear.tr,
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
