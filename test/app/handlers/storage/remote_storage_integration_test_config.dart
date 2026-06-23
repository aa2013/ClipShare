import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'remote_storage_integration_test_target.dart';

/// 远端存储集成测试配置加载器，统一负责读取本地敏感配置。
final class RemoteStorageIntegrationTestConfigLoader {
  const RemoteStorageIntegrationTestConfigLoader._();

  /// 默认读取的本地 JSON 文件路径。
  static const String localConfigPath = 'test/app/handlers/storage/remote_storage_integration.config.json';

  /// 可提交的示例 JSON 文件路径，便于开发者复制填写。
  static const String exampleConfigPath = 'test/app/handlers/storage/remote_storage_integration.config.example.json';

  /// 判断本地私有配置是否存在，便于测试入口按需跳过。
  static bool hasLocalConfig({
    String configPath = localConfigPath,
  }) {
    return File(configPath).existsSync();
  }

  /// 从本地 JSON 读取所有远端存储集成测试目标。
  static List<RemoteStorageIntegrationTarget> loadTargets({
    String configPath = localConfigPath,
  }) {
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      fail(
        'Missing remote storage integration test config: $configPath\n'
        'Copy $exampleConfigPath and fill in your private credentials before running this test.',
      );
    }

    final dynamic decodedJson = jsonDecode(configFile.readAsStringSync());
    if (decodedJson is! Map<String, dynamic>) {
      fail('Invalid remote storage integration test config: root JSON must be an object.');
    }

    final dynamic targetsJson = decodedJson['targets'];
    if (targetsJson is! List<dynamic> || targetsJson.isEmpty) {
      fail('Invalid remote storage integration test config: "targets" must be a non-empty array.');
    }

    return targetsJson
        .map<RemoteStorageIntegrationTarget>((dynamic item) {
          if (item is! Map<String, dynamic>) {
            fail('Invalid remote storage integration test config: each target must be an object.');
          }

          final dynamic storageTypeJson = item['storageType'];
          final dynamic configJson = item['config'];
          final bool enabled = item["enabled"] ?? true;
          if (storageTypeJson is! String || storageTypeJson.trim().isEmpty) {
            fail('Invalid remote storage integration test config: "storageType" must be a non-empty string.');
          }
          if (configJson is! Map<String, dynamic>) {
            fail('Invalid remote storage integration test config: "config" must be an object.');
          }

          late final RemoteStorageIntegrationTarget target;
          switch (storageTypeJson) {
            case 'webdav':
              target = WebDavIntegrationTarget.fromJson(configJson, enabled);
              _validateWebDavTarget(target);
              break;
            case 's3':
              target = S3IntegrationTarget.fromJson(configJson, enabled);
              _validateS3Target(target);
              break;
            default:
              fail('Invalid remote storage integration test config: unsupported storageType "$storageTypeJson".');
          }
          return target;
        })
        .where((item) => item.enabled)
        .toList(growable: false);
  }

  /// 校验 WebDAV 测试目标必填字段，避免运行中才发现配置损坏。
  static void _validateWebDavTarget(RemoteStorageIntegrationTarget target) {
    final webDavTarget = target as WebDavIntegrationTarget;
    if (webDavTarget.config.displayName.trim().isEmpty) {
      fail('Invalid remote storage integration test config: WebDAV "displayName" cannot be empty.');
    }
    if (webDavTarget.config.server.trim().isEmpty) {
      fail('Invalid remote storage integration test config: WebDAV "server" cannot be empty.');
    }
    if (webDavTarget.config.username.trim().isEmpty) {
      fail('Invalid remote storage integration test config: WebDAV "username" cannot be empty.');
    }
    if (webDavTarget.config.password.trim().isEmpty) {
      fail('Invalid remote storage integration test config: WebDAV "password" cannot be empty.');
    }
    if (webDavTarget.config.baseDir.trim().isEmpty) {
      fail('Invalid remote storage integration test config: WebDAV "baseDir" cannot be empty.');
    }
  }

  /// 校验 S3 / OSS 测试目标必填字段，保持失败信息足够具体。
  static void _validateS3Target(RemoteStorageIntegrationTarget target) {
    final s3Target = target as S3IntegrationTarget;
    if (s3Target.config.displayName.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "displayName" cannot be empty.');
    }
    if (s3Target.config.endPoint.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "endPoint" cannot be empty.');
    }
    if (s3Target.config.accessKey.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "accessKey" cannot be empty.');
    }
    if (s3Target.config.secretKey.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "secretKey" cannot be empty.');
    }
    if (s3Target.config.bucketName.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "bucketName" cannot be empty.');
    }
    if (s3Target.config.baseDir.trim().isEmpty) {
      fail('Invalid remote storage integration test config: S3 "baseDir" cannot be empty.');
    }
  }
}
