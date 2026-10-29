import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/runtime/app_update/utils/app_update_installer.dart';
import 'package:clipshare/features/app_update/utils/app_update_dialog.dart';
import 'package:clipshare/features/app_update/widgets/app_update_dialog.dart';
import 'package:clipshare/features/app_update/widgets/app_update_installer_selector.dart';
import 'package:clipshare/shared/models/update_log.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录界面传给 runtime 的版本，不访问真实配置数据库。
class _RecordingUpdateNotifier extends AppUpdateNotifier {
  String? ignored;

  @override
  void build() {}

  @override
  Future<void> ignoreVersion(String versionCode) async {
    ignored = versionCode;
  }
}

/// 构造不同说明的不可变检查结果，避免网络与设备依赖。
AppUpdateCheckResult result(String description) => AppUpdateCheckResult(
  status: AppUpdateCheckStatus.available,
  logs: [UpdateLog(platform: 'all', date: DateTime(2026), version: const AppVersion('2.0', '20'),
    desc: description, downloadUrl: 'https://example.com/setup.exe')],
);

/// 供弹窗调用使用的稳定宿主上下文。
Future<BuildContext> pumpHost(WidgetTester tester) async {
  late BuildContext host;
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Builder(
    builder: (context) {
      host = context;
      return const Scaffold();
    },
  ))));
  return host;
}

/// 先推进退场动画再等待关闭 future，避免虚拟时钟被阻塞。
Future<void> cleanup(WidgetTester tester) async {
  final closing = closeAppUpdateDialog();
  await tester.pumpAndSettle();
  await closing;
  await dialogManager.closeAll();
  await tester.pumpAndSettle();
  DialogManager.suppressTips = null;
}

void main() {
  test('替换扩展名保留查询参数与片段', () {
    expect(AppUpdateInstaller.replaceUrlExtension('https://a.test/dir.a/setup.exe?token=a.b#part', '.zip'),
      'https://a.test/dir.a/setup.zip?token=a.b#part');
    expect(AppUpdateInstaller.replaceUrlExtension('https://a.test/dir.a/setup', '.deb'),
      'https://a.test/dir.a/setup.deb');
  });

  testWidgets('跳过版本操作通过runtime保存版本并关闭窗口', (tester) async {
    final notifier = _RecordingUpdateNotifier();
    late BuildContext host;
    await tester.pumpWidget(ProviderScope(
      overrides: [appUpdateProvider.overrideWith(() => notifier)],
      child: MaterialApp(home: Builder(builder: (context) {
        host = context;
        return const Scaffold();
      })),
    ));
    await showAppUpdateDialog(host, result('ignore-me'), sendNotification: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();
    expect(notifier.ignored, '20');
    expect(find.byType(AppUpdateDialog), findsNothing);
    await cleanup(tester);
  });

  testWidgets('替换只保留最新说明，旧状态的notifier被释放', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('first'), sendNotification: false);
    await tester.pumpAndSettle();
    final selector = tester.widget<AppUpdateInstallerSelector>(find.byType(AppUpdateInstallerSelector));
    final oldNotifier = selector.selectedType;
    final replacement = showAppUpdateDialog(host, result('second'), sendNotification: false);
    await tester.pumpAndSettle();
    expect(await replacement, isTrue);
    expect(find.textContaining('first'), findsNothing);
    expect(find.textContaining('second'), findsOneWidget);
    expect(() => oldNotifier.addListener(() {}), throwsFlutterError);
    await cleanup(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('并发请求仅最新生效，旧窗口关闭回调不误关新窗口', (tester) async {
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('initial'), sendNotification: false);
    await tester.pumpAndSettle();
    final oldWidget = tester.widget<AppUpdateDialog>(find.byType(AppUpdateDialog));
    final a = showAppUpdateDialog(host, result('stale'), sendNotification: false);
    final b = showAppUpdateDialog(host, result('latest'), sendNotification: false);
    await tester.pumpAndSettle();
    await Future.wait([a, b]);
    await oldWidget.onClose();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    expect(find.textContaining('latest'), findsOneWidget);
    expect(find.textContaining('stale'), findsNothing);
    await cleanup(tester);
  });

  testWidgets('更新窗口被其它窗口遮挡时替换不关闭其它窗口', (tester) async {
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('first'), sendNotification: false);
    await tester.pumpAndSettle();
    final other = dialogManager.open(host, const AlertDialog(content: Text('other')));
    await tester.pumpAndSettle();
    final replacing = showAppUpdateDialog(host, result('second'), sendNotification: false);
    await tester.pumpAndSettle();
    await replacing;
    expect(other.closed, isFalse);
    expect(find.text('other'), findsOneWidget);
    expect(find.textContaining('first'), findsNothing);
    expect(find.textContaining('second'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('首帧前替换仍只保留最新窗口', (tester) async {
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('unmounted-first'), sendNotification: false);
    final replacing = showAppUpdateDialog(host, result('mounted-latest'), sendNotification: false);
    await tester.pumpAndSettle();
    expect(await replacing, isTrue);
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    expect(find.textContaining('mounted-latest'), findsOneWidget);
    await cleanup(tester);
  });

  testWidgets('显式关闭使排队展示请求失效', (tester) async {
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('first'), sendNotification: false);
    await tester.pumpAndSettle();
    final replacing = showAppUpdateDialog(host, result('cancelled'), sendNotification: false);
    final closing = closeAppUpdateDialog();
    await tester.pumpAndSettle();
    expect(await replacing, isFalse);
    await closing;
    expect(find.byType(AppUpdateDialog), findsNothing);
    await cleanup(tester);
  });

  testWidgets('应用锁和非available结果不会打开更新窗口', (tester) async {
    final host = await pumpHost(tester);
    DialogManager.suppressTips = () => true;
    expect(await showAppUpdateDialog(host, result('locked'), sendNotification: false), isFalse);
    DialogManager.suppressTips = null;
    for (final status in [AppUpdateCheckStatus.upToDate, AppUpdateCheckStatus.ignored, AppUpdateCheckStatus.failed]) {
      expect(await showAppUpdateDialog(host, AppUpdateCheckResult(status: status), sendNotification: false), isFalse);
    }
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    await cleanup(tester);
  });

  testWidgets('替换退场期间进入应用锁时放弃展示', (tester) async {
    final host = await pumpHost(tester);
    await showAppUpdateDialog(host, result('first'), sendNotification: false);
    await tester.pumpAndSettle();
    final replacing = showAppUpdateDialog(host, result('locked'), sendNotification: false);
    await tester.pump();
    DialogManager.suppressTips = () => true;
    await tester.pumpAndSettle();
    expect(await replacing, isFalse);
    expect(find.byType(AppUpdateDialog), findsNothing);
    await cleanup(tester);
  });
}
