import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemThemeModeSync extends ConsumerStatefulWidget {
  final Widget child;
  final void Function() onThemeChanged;

  const SystemThemeModeSync({
    super.key,
    required this.child,
    required this.onThemeChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SystemThemeModeSyncState();
}

class _SystemThemeModeSyncState extends ConsumerState<SystemThemeModeSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangePlatformBrightness() async {
    widget.onThemeChanged();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
