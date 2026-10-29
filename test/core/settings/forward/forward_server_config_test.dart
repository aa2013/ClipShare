import 'package:clipshare/core/settings/forward/forward_server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForwardServerConfig.tryParse', () {
    test('parses json config with key', () {
      final config = ForwardServerConfig.tryParse('{"host":"example.com","port":8080,"key":"abc"}');

      expect(config, isNotNull);
      expect(config!.host, 'example.com');
      expect(config.port, 8080);
      expect(config.key, 'abc');
    });

    test('parses json config and treats empty key as null', () {
      final config = ForwardServerConfig.tryParse('{"host":"example.com","port":8080,"key":""}');

      expect(config, isNotNull);
      expect(config!.key, isNull);
    });

    test('parses legacy host:port format', () {
      final config = ForwardServerConfig.tryParse('192.168.1.10:12345');

      expect(config, isNotNull);
      expect(config!.host, '192.168.1.10');
      expect(config.port, 12345);
      expect(config.key, isNull);
    });

    test('returns null for malformed input', () {
      // 缺少端口，旧格式拆分失败
      expect(ForwardServerConfig.tryParse('not-a-config'), isNull);
      // JSON 不完整
      expect(ForwardServerConfig.tryParse('{broken json'), isNull);
      // 旧格式多余分段
      expect(ForwardServerConfig.tryParse('1.2.3.4:1:2'), isNull);
    });
  });
}
