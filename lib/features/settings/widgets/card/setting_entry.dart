import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/widgets.dart';

abstract interface class SettingEntry {
  bool get visible;

  String get searchId;

  List<TranslationKey> get searchKeys;

  List<String> get searchAliases;

  Widget buildWithLayout({
    required BorderRadius borderRadius,
    required bool separate,
  });
}
