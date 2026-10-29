import 'dart:convert';

import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupVersionInfo', () {
    test('serializes to json and restores the same values', () {
      const info = BackupVersionInfo(12, 300, 'device-name', 'guid-1234');
      final restored = BackupVersionInfo.fromJson(jsonDecode(info.toString()) as Map<String, dynamic>);
      expect(restored.dbVersion, 12);
      expect(restored.appVersion, 300);
      expect(restored.devName, 'device-name');
      expect(restored.devId, 'guid-1234');
    });

    test('toString produces the version.json json body', () {
      const info = BackupVersionInfo(1, 2, 'n', 'd');
      final map = jsonDecode(info.toString()) as Map<String, dynamic>;
      expect(map.keys, containsAll(['dbVersion', 'appVersion', 'devName', 'devId']));
    });
  });
}
