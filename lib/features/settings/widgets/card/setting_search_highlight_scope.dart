import 'package:flutter/widgets.dart';

class SettingSearchHighlightScope extends InheritedWidget {
  final String? searchId;

  const SettingSearchHighlightScope({
    super.key,
    required this.searchId,
    required super.child,
  });

  static SettingSearchHighlightScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingSearchHighlightScope>();
  }

  @override
  bool updateShouldNotify(SettingSearchHighlightScope oldWidget) {
    return searchId != oldWidget.searchId;
  }
}
