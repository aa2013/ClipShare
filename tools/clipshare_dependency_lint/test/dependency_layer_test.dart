import 'package:test/test.dart';

import '../lib/src/dependency_direction_rule.dart';

void main() {
  group('layerOfFile', () {
    test('shared 目录（Windows/posix 路径）', () {
      expect(
        layerOfFile(r'C:\proj\lib\shared\models\a.dart'),
        DependencyLayer.shared,
      );
      expect(
        layerOfFile('/proj/lib/shared/models/a.dart'),
        DependencyLayer.shared,
      );
    });

    test('core 目录', () {
      expect(
        layerOfFile(r'C:\proj\lib\core\database\a.dart'),
        DependencyLayer.core,
      );
    });

    test('features 目录', () {
      expect(
        layerOfFile(r'C:\proj\lib\features\home\a.dart'),
        DependencyLayer.features,
      );
    });

    test('lib 根目录文件（组装层）返回 null', () {
      expect(layerOfFile(r'C:\proj\lib\main.dart'), isNull);
      expect(layerOfFile(r'C:\proj\lib\app.dart'), isNull);
    });

    test('lib 之外目录与相近目录名返回 null', () {
      expect(layerOfFile(r'C:\proj\test\core\a.dart'), isNull);
      expect(layerOfFile(r'C:\proj\lib\corex\a.dart'), isNull);
    });
  });

  group('layerOfPackageUri', () {
    test('各层', () {
      expect(
        layerOfPackageUri('package:clipshare/shared/models/a.dart'),
        DependencyLayer.shared,
      );
      expect(
        layerOfPackageUri('package:clipshare/core/db.dart'),
        DependencyLayer.core,
      );
      expect(
        layerOfPackageUri('package:clipshare/features/home/page.dart'),
        DependencyLayer.features,
      );
    });

    test('lib 根目录文件返回 null', () {
      expect(layerOfPackageUri('package:clipshare/app.dart'), isNull);
    });

    test('非 clipshare 包返回 null', () {
      expect(layerOfPackageUri('package:flutter/material.dart'), isNull);
      expect(layerOfPackageUri('dart:core'), isNull);
    });
  });
}
