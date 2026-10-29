import 'package:clipshare/features/auth/providers/app_lock_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRevalidateOnResume', () {
    final now = DateTime(2026, 1, 1, 12, 0, 0);

    test('returns false when pausedTime is null', () {
      // 从未记录切后台时间（或验证期间切后台）时不触发重验
      final result = shouldRevalidateOnResume(
        pausedTime: null,
        revalidateDurationMinutes: 0,
        now: now,
      );
      expect(result, isFalse);
    });

    test('returns true immediately when duration is zero', () {
      // 配置为“立即”时，无论离开多久都触发重验
      final pausedTime = now.subtract(const Duration(seconds: 1));
      final result = shouldRevalidateOnResume(
        pausedTime: pausedTime,
        revalidateDurationMinutes: 0,
        now: now,
      );
      expect(result, isTrue);
    });

    test('returns false when elapsed minutes are less than duration', () {
      // 离开 4 分 59 秒，配置 5 分钟：不足 5 整分钟，不触发
      final pausedTime = now.subtract(const Duration(minutes: 4, seconds: 59));
      final result = shouldRevalidateOnResume(
        pausedTime: pausedTime,
        revalidateDurationMinutes: 5,
        now: now,
      );
      expect(result, isFalse);
    });

    test('returns true when elapsed minutes equal duration', () {
      // 恰好离开 5 分钟：满足 >= 配置时长，触发
      final pausedTime = now.subtract(const Duration(minutes: 5));
      final result = shouldRevalidateOnResume(
        pausedTime: pausedTime,
        revalidateDurationMinutes: 5,
        now: now,
      );
      expect(result, isTrue);
    });

    test('returns true when elapsed minutes exceed duration', () {
      final pausedTime = now.subtract(const Duration(minutes: 30));
      final result = shouldRevalidateOnResume(
        pausedTime: pausedTime,
        revalidateDurationMinutes: 5,
        now: now,
      );
      expect(result, isTrue);
    });
  });

  group('shouldLockOnStartup', () {
    test('returns false when authentication is disabled', () {
      final result = shouldLockOnStartup(
        useAuthentication: false,
        isDesktop: false,
        startMini: false,
      );
      expect(result, isFalse);
    });

    test('returns true on mobile regardless of startMini', () {
      // 最小化启动仅对桌面端有意义，移动端始终锁定
      final result = shouldLockOnStartup(
        useAuthentication: true,
        isDesktop: false,
        startMini: true,
      );
      expect(result, isTrue);
    });

    test('returns false on desktop when starting minimized', () {
      final result = shouldLockOnStartup(
        useAuthentication: true,
        isDesktop: true,
        startMini: true,
      );
      expect(result, isFalse);
    });

    test('returns true on desktop when not starting minimized', () {
      final result = shouldLockOnStartup(
        useAuthentication: true,
        isDesktop: true,
        startMini: false,
      );
      expect(result, isTrue);
    });
  });
}
