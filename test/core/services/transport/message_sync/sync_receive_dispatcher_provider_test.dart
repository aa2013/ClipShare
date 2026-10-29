import 'dart:convert';

import 'package:clipshare/core/services/transport/message_sync/sync_receive_dispatcher_provider.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:flutter_test/flutter_test.dart';

/// 调用载荷归一化函数，固定模块与操作 id 便于定位日志。
Map<String, dynamic> _normalize(Object? rawData) {
  return normalizeSyncEntityData(
    rawData,
    module: Module.appInfo,
    opId: 1,
  );
}

void main() {
  group('normalizeSyncEntityData', () {
    test('returns map payload as is', () {
      final payload = <String, dynamic>{'id': 1, 'appId': 'com.example.app'};

      expect(_normalize(payload), equals(payload));
    });

    test('decodes json string payload', () {
      final result = _normalize(jsonEncode(<String, dynamic>{'id': 1, 'name': 'Example'}));

      expect(result['id'], 1);
      expect(result['name'], 'Example');
    });

    test('returns empty map for invalid json string', () {
      expect(_normalize('{invalid'), isEmpty);
    });

    test('returns empty map when json is not an object', () {
      expect(_normalize(jsonEncode(<int>[1, 2, 3])), isEmpty);
      expect(_normalize(jsonEncode(1)), isEmpty);
    });

    test('returns empty map for empty or unsupported payload', () {
      expect(_normalize(''), isEmpty);
      expect(_normalize(null), isEmpty);
      expect(_normalize(1), isEmpty);
    });
  });
}
