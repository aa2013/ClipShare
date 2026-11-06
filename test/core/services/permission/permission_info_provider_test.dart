import 'package:clipshare/core/services/permission/permission_info.dart';
import 'package:clipshare/core/services/permission/permission_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 仅提供过期缓存，不替换真实权限查询和请求方法。
class _PermissionNotifier extends PermissionInfoNotifier {
  /// 模拟系统权限变化后仍保留的旧缓存。
  void seedStalePermission() {
    state = const AsyncData(PermissionInfo(hasAccessibilityPermission: true));
  }
}

void main() {
  testWidgets('请求完成后主动复查权限，不依赖 resumed 事件', (tester) async {
    final notifier = _PermissionNotifier();
    final container = ProviderContainer(overrides: [
      permissionInfoProvider.overrideWith(() => notifier),
    ]);
    addTearDown(container.dispose);
    final initial = await container.read(permissionInfoProvider.future);
    notifier.seedStalePermission();
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
      context = value;
      return const SizedBox();
    })));
    await notifier.requestAccessibilityPermission(context);
    final refreshed = container.read(permissionInfoProvider).requireValue;
    expect(refreshed.hasAccessibilityPermission, initial.hasAccessibilityPermission);
    expect(identical(refreshed, initial), isFalse);
  });

  testWidgets('返回前台后复查权限缓存', (tester) async {
    final notifier = _PermissionNotifier();
    final container = ProviderContainer(overrides: [
      permissionInfoProvider.overrideWith(() => notifier),
    ]);
    addTearDown(container.dispose);
    final initial = await container.read(permissionInfoProvider.future);
    notifier.seedStalePermission();
    await notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    final refreshed = container.read(permissionInfoProvider).requireValue;
    expect(refreshed.hasAccessibilityPermission, initial.hasAccessibilityPermission);
    expect(identical(refreshed, initial), isFalse);
  });
}
