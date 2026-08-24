import 'package:clipshare/core/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试宿主：为弹窗 API 提供合法 context。
class _DialogHost extends StatefulWidget {
  const _DialogHost();

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('dialog-host')),
    );
  }
}

void main() {
  /// 渲染宿主并返回其 state，供各用例获得可用 BuildContext。
  Future<_DialogHostState> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _DialogHost()),
    );
    return tester.state<_DialogHostState>(find.byType(_DialogHost));
  }

  /// 用例结束清理：关闭所有存活弹窗并等待动画结束，避免
  /// static 注册表与同内容去重集合污染下一个用例。
  Future<void> closeRemaining(WidgetTester tester) async {
    await dialogManager.closeAll();
    await tester.pumpAndSettle();
  }

  /// 依次弹出三个内容不同的提示弹窗（避开同内容去重），返回对应控制器。
  Future<List<DialogController?>> openThreeTips(
    WidgetTester tester,
    BuildContext context,
  ) async {
    final first = await dialogManager.tips(context, text: 'AAA');
    final second = await dialogManager.tips(context, text: 'BBB');
    final third = await dialogManager.tips(context, text: 'CCC');
    await tester.pumpAndSettle();
    return [first, second, third];
  }

  group('DialogManager 多弹窗与关闭', () {
    testWidgets('三个提示弹窗可同时叠放显示', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      expect(dialogs, hasLength(3));
      expect(dialogs.whereType<DialogController>(), hasLength(3));
      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('BBB'), findsOneWidget);
      expect(find.text('CCC'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('关闭中间弹窗：仅中间消失，上下弹窗保留', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final middle = dialogs[1]!;
      final closed = await middle.close();
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(middle.closed, isTrue);
      expect(find.text('BBB'), findsNothing);
      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('CCC'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('重复关闭已关闭弹窗是幂等的', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final middle = dialogs[1]!;
      await middle.close();
      await tester.pumpAndSettle();

      final secondClose = await middle.close();
      await tester.pumpAndSettle();

      expect(secondClose, isTrue);
      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('CCC'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('关闭栈顶弹窗走 pop 路径：仅栈顶消失', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final top = dialogs[2]!;
      final closed = await top.close();
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('CCC'), findsNothing);
      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('BBB'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('closeById 可关闭中间弹窗', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final middle = dialogs[1]!;
      final closed = await dialogManager.closeById(middle.id);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('BBB'), findsNothing);
      expect(find.text('AAA'), findsOneWidget);
      expect(find.text('CCC'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('closeById 对已关闭 id 返回 false', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final top = dialogs[2]!;
      await top.close();
      await tester.pumpAndSettle();

      final closed = await dialogManager.closeById(top.id);
      expect(closed, isFalse);

      await closeRemaining(tester);
    });

    testWidgets('closeAll 一次关闭全部弹窗并清空注册表', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      await dialogManager.closeAll();
      await tester.pumpAndSettle();

      expect(find.text('AAA'), findsNothing);
      expect(find.text('BBB'), findsNothing);
      expect(find.text('CCC'), findsNothing);
      expect(dialogs.every((dialog) => dialog!.closed), isTrue);

      await closeRemaining(tester);
    });

    testWidgets('关闭中间弹窗后注册表不残留该弹窗', (tester) async {
      final state = await pumpHost(tester);
      final dialogs = await openThreeTips(tester, state.context);

      final middle = dialogs[1]!;
      await middle.close();
      await tester.pumpAndSettle();

      final reopened = await dialogManager.closeById(middle.id);
      expect(reopened, isFalse);

      await closeRemaining(tester);
    });
  });

  group('tips 按钮行为', () {
    testWidgets('默认仅显示一个确定按钮，点击后自动关闭', (tester) async {
      final state = await pumpHost(tester);
      await dialogManager.tips(state.context, text: 'hello');
      await tester.pumpAndSettle();

      // 兜底文案来自英文翻译，不依赖运行时语言绑定。
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsNothing);

      await closeRemaining(tester);
    });

    testWidgets('配置 cancel 与 neutral 槽位后按钮全部显示', (tester) async {
      final state = await pumpHost(tester);
      await dialogManager.tips(
        state.context,
        text: 'confirm message',
        actions: const DialogActions(
          confirm: DialogAction(text: 'CONFIRM'),
          cancel: DialogAction(text: 'CANCEL'),
          neutral: DialogAction(text: 'NEUTRAL'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('NEUTRAL'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('确认按钮回调可被触发', (tester) async {
      final state = await pumpHost(tester);
      var confirmed = false;
      await dialogManager.tips(
        state.context,
        text: 'callback message',
        actions: DialogActions(
          confirm: DialogAction(
            text: 'GO',
            onPressed: () {
              confirmed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('callback message'), findsNothing);

      await closeRemaining(tester);
    });

    testWidgets('autoDismiss=false 时点击按钮不会自动关闭', (tester) async {
      final state = await pumpHost(tester);
      await dialogManager.tips(
        state.context,
        text: 'keep open',
        autoDismiss: false,
        actions: const DialogActions(
          confirm: DialogAction(text: 'CONFIRM'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONFIRM'));
      await tester.pumpAndSettle();

      expect(find.text('keep open'), findsOneWidget);

      await closeRemaining(tester);
    });

    testWidgets('不传按钮槽位时弹窗无按钮', (tester) async {
      final state = await pumpHost(tester);
      await dialogManager.tips(
        state.context,
        text: 'no actions',
        actions: const DialogActions(
          confirm: null,
          cancel: null,
          neutral: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('no actions'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);

      await closeRemaining(tester);
    });
  });
}
