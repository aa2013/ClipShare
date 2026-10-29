import 'package:clipshare/features/settings/utils/dh_key_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DhKeyValidator.verify', () {
    test('empty input passes only when a current key exists', () {
      // 已配置密钥时允许输入为空（表示清空）
      final canClear = DhKeyValidator.verify('', hasCurrentKey: true);
      final cannotSet = DhKeyValidator.verify('', hasCurrentKey: false);
      expect(canClear, isTrue);
      expect(cannotSet, isFalse);
    });

    test('rejects input shorter than minLength', () {
      final result = DhKeyValidator.verify('1234567', hasCurrentKey: false);
      expect(result, isFalse);
    });

    test('accepts input exactly at minLength', () {
      final result = DhKeyValidator.verify('12345678', hasCurrentKey: false);
      expect(result, isTrue);
    });

    test('accepts input longer than minLength', () {
      final result = DhKeyValidator.verify('1234567890abc', hasCurrentKey: false);
      expect(result, isTrue);
    });

    test('strips whitespace escape sequences before measuring length', () {
      // 转义序列不计入长度：去除后剩余 7 位则拒绝
      final tooShort = DhKeyValidator.verify('\\s+abcdefg', hasCurrentKey: false);
      // 去除后剩余 8 位则通过
      final enough = DhKeyValidator.verify('\\s+abcdefgh', hasCurrentKey: false);
      expect(tooShort, isFalse);
      expect(enough, isTrue);
    });
  });
}
