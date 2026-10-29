import 'dart:async';

import 'package:clipshare/shared/extensions/cancellable_extension.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试用取消标记异常
class _TestCancelError implements Exception {
  const _TestCancelError();

  @override
  String toString() => 'TestCancelError';
}

void main() {
  group('Stream.cancellable', () {
    test('ends the stream right after cancel without new data events', () async {
      final source = StreamController<int>();
      final tokenSource = CancelTokenSource();
      final output = source.stream.cancellable(
        tokenSource.token,
        cancelError: () => const _TestCancelError(),
      );
      final received = <int>[];
      final errors = <Object>[];
      final done = Completer<void>();
      output.listen(
        received.add,
        onError: errors.add,
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
      );
      source.add(1);
      await Future<void>.delayed(Duration.zero);

      tokenSource.cancel();
      await done.future;

      expect(received, [1]);
      expect(errors.single, isA<_TestCancelError>());
      // 取消后源订阅被断开，不会再向上游索取数据
      expect(source.hasListener, isFalse);
      await source.close();
    });

    test('works for non-byte element types', () async {
      final source = StreamController<String>();
      final tokenSource = CancelTokenSource();
      final output = source.stream.cancellable(
        tokenSource.token,
        cancelError: () => const _TestCancelError(),
      );
      final received = <String>[];
      final errors = <Object>[];
      final done = Completer<void>();
      output.listen(
        received.add,
        onError: errors.add,
        onDone: done.complete,
      );
      source.add('a');
      await Future<void>.delayed(Duration.zero);

      tokenSource.cancel();
      await done.future;

      expect(received, ['a']);
      expect(errors.single, isA<_TestCancelError>());
      await source.close();
    });

    test('passes data through when no token is given', () async {
      final source = StreamController<int>();
      final output = source.stream.cancellable(
        null,
        cancelError: () => const _TestCancelError(),
      );
      final received = <int>[];
      final done = Completer<void>();
      output.listen(received.add, onDone: done.complete);
      source.add(1);
      source.add(2);
      await source.close();
      await done.future;

      expect(received, [1, 2]);
    });

    test('forwards pause and resume to the source', () async {
      final source = StreamController<int>();
      final tokenSource = CancelTokenSource();
      final output = source.stream.cancellable(
        tokenSource.token,
        cancelError: () => const _TestCancelError(),
      );
      final received = <int>[];
      late StreamSubscription<int> subscription;
      subscription = output.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      subscription.pause();
      await Future<void>.delayed(Duration.zero);
      expect(source.isPaused, isTrue);

      subscription.resume();
      await Future<void>.delayed(Duration.zero);
      expect(source.isPaused, isFalse);

      source.add(7);
      await Future<void>.delayed(Duration.zero);
      expect(received, [7]);

      await subscription.cancel();
      await source.close();
    });
  });

  group('Future.orCancel', () {
    test('returns the future value when not canceled', () async {
      final tokenSource = CancelTokenSource();
      final result = await Future<int>.value(7).orCancel(
        tokenSource.token,
        cancelError: () => const _TestCancelError(),
      );

      expect(result, 7);
    });

    test('throws immediately when canceled before completion', () async {
      final tokenSource = CancelTokenSource();
      final pending = Completer<int>();
      final expectation = expectLater(
        pending.future.orCancel(tokenSource.token, cancelError: () => const _TestCancelError()),
        throwsA(isA<_TestCancelError>()),
      );

      tokenSource.cancel();
      await expectation;
    });

    test('throws when the token is already canceled', () async {
      final tokenSource = CancelTokenSource();
      tokenSource.cancel();

      await expectLater(
        Future<void>.value().orCancel(tokenSource.token, cancelError: () => const _TestCancelError()),
        throwsA(isA<_TestCancelError>()),
      );
    });

    test('absorbs the underlying failure after cancel', () async {
      final tokenSource = CancelTokenSource();
      final pending = Completer<int>();
      final future = pending.future.orCancel(
        tokenSource.token,
        cancelError: () => const _TestCancelError(),
      );
      tokenSource.cancel();
      await expectLater(future, throwsA(isA<_TestCancelError>()));

      // 取消后底层仍可能失败，异常必须被吸收而不是变成未捕获错误
      pending.completeError(StateError('late failure'));
      await Future<void>.delayed(Duration.zero);
    });
  });
}
