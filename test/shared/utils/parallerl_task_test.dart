import 'dart:async';

import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancelToken register', () {
    test('runs callbacks in reverse registration order', () {
      final source = CancelTokenSource();
      final calls = <int>[];
      source.token.register(() => calls.add(1));
      source.token.register(() => calls.add(2));

      source.cancel();

      expect(calls, [2, 1]);
      expect(source.token.isCanceled, isTrue);
    });

    test('runs callbacks only once on repeated cancel', () {
      final source = CancelTokenSource();
      var count = 0;
      source.token.register(() => count++);

      source.cancel();
      source.cancel();

      expect(count, 1);
    });

    test('runs callback registered after cancel immediately', () {
      final source = CancelTokenSource();
      source.cancel();
      var called = false;

      final registration = source.token.register(() => called = true);

      expect(called, isTrue);
      // 已失效的凭据注销时不应抛错。
      expect(registration.dispose, returnsNormally);
    });

    test('keeps other callbacks running when one throws', () {
      final source = CancelTokenSource();
      final calls = <int>[];
      source.token.register(() => throw StateError('boom'));
      source.token.register(() => calls.add(1));

      source.cancel();

      // 抛错回调先注册，因此后执行；异常被收口后不应影响已执行的回调。
      expect(calls, [1]);
    });

    test('lets async callback finish after cancel returns', () async {
      final source = CancelTokenSource();
      var completed = false;
      source.token.register(() async {
        await Future<void>.delayed(Duration.zero);
        completed = true;
      });

      source.cancel();

      expect(source.token.isCanceled, isTrue);
      expect(completed, isFalse);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isTrue);
    });
  });

  group('CancelTokenRegistration dispose', () {
    test('removes callback before cancel', () {
      final source = CancelTokenSource();
      var called = false;
      final registration = source.token.register(() => called = true);

      registration.dispose();
      source.cancel();

      expect(called, isFalse);
    });

    test('is safe after cancel', () {
      final source = CancelTokenSource();
      final registration = source.token.register(() {});

      source.cancel();

      expect(registration.dispose, returnsNormally);
      expect(registration.dispose, returnsNormally);
    });

    test('removes only its own registration', () {
      final source = CancelTokenSource();
      var count = 0;
      final callback = () => count++;
      final first = source.token.register(callback);
      source.token.register(callback);

      first.dispose();
      source.cancel();

      expect(count, 1);
    });

    test('skips registration disposed by another callback', () {
      final source = CancelTokenSource();
      var executed = false;
      final registration = source.token.register(() => executed = true);
      // 后注册先执行，先撤销前一个回调。
      source.token.register(registration.dispose);

      source.cancel();

      expect(executed, isFalse);
    });
  });

  group('CancelToken.none', () {
    test('never invokes callbacks', () {
      var called = false;
      final registration = CancelToken.none.register(() => called = true);

      expect(called, isFalse);
      expect(registration.dispose, returnsNormally);
      expect(called, isFalse);
    });
  });

  group('CompositeCancelToken', () {
    test('fires once when any child token is canceled', () {
      final local = CancelTokenSource();
      final external = CancelTokenSource();
      final token = local.token.combine(external.token);
      var count = 0;
      token.register(() => count++);

      external.cancel();
      expect(count, 1);

      local.cancel();
      expect(count, 1);
    });

    test('stops firing after registration disposed', () {
      final local = CancelTokenSource();
      final external = CancelTokenSource();
      final token = local.token.combine(external.token);
      var called = false;
      final registration = token.register(() => called = true);

      registration.dispose();
      external.cancel();
      local.cancel();

      expect(called, isFalse);
    });

    test('runs callback immediately when a child was already canceled', () {
      final local = CancelTokenSource();
      final external = CancelTokenSource();
      external.cancel();
      final token = local.token.combine(external.token);
      var called = false;

      token.register(() => called = true);

      expect(called, isTrue);
      expect(token.isCanceled, isTrue);
    });
  });
}
