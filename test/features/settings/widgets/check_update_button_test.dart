import 'dart:async';

import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/features/settings/widgets/check_update_button.dart';
import 'package:clipshare/l10n/gen/app_localizations_en.dart';
import 'package:clipshare/l10n/l10n_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只替换网络运行时，验证按钮真实的等待与结果交互。
class _UpdateNotifier extends AppUpdateNotifier {
  final response = Completer<AppUpdateCheckResult>();
  bool? requestedForce;
  int calls = 0;

  @override
  void build() {}

  /// 保留未完成的请求，以验证加载中禁止重复触发。
  @override
  Future<AppUpdateCheckResult> checkUpdate({bool forceCheck = false}) {
    calls++;
    requestedForce = forceCheck;
    return response.future;
  }
}

void main() {
  setUp(() {
    L10nBridge.bind(AppLocalizationsEn());
  });

  testWidgets('手动强制检查等待结果，加载中禁用按钮，无更新恢复按钮', (tester) async {
    final updater = _UpdateNotifier();
    await tester.pumpWidget(ProviderScope(
      overrides: [appUpdateProvider.overrideWith(() => updater)],
      child: const MaterialApp(home: Scaffold(body: CheckUpdateButton())),
    ));
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(updater.requestedForce, isTrue);
    expect(updater.calls, 1);
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    updater.response.complete(AppUpdateCheckResult(status: AppUpdateCheckStatus.upToDate));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);
    // 成功提示有独立的三秒寿命，等待真实关闭计时器完成。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('离开设置页后完成检查不会更新已销毁状态', (tester) async {
    final updater = _UpdateNotifier();
    await tester.pumpWidget(ProviderScope(
      overrides: [appUpdateProvider.overrideWith(() => updater)],
      child: const MaterialApp(home: Scaffold(body: CheckUpdateButton())),
    ));
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    updater.response.complete(AppUpdateCheckResult(status: AppUpdateCheckStatus.upToDate));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
