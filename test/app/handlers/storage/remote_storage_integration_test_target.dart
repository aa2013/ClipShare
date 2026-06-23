import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/utils/extensions/storage_config_extension.dart';

/// 远端存储集成测试支持的配置类型。
enum RemoteStorageIntegrationKind {
  webdav,
  s3,
}

/// 远端存储集成测试目标的公共抽象，统一暴露测试所需的最小能力。
abstract class RemoteStorageIntegrationTarget {
  const RemoteStorageIntegrationTarget();

  /// 标识当前目标使用的远端存储类型。
  RemoteStorageIntegrationKind get kind;

  /// 是否启用
  bool get enabled;

  /// 显示名称会直接进入测试分组名，便于快速定位失败目标。
  String get displayName;

  /// 稳定的文件系统安全标识，便于拼接临时目录名。
  String get slug => displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  /// 构建默认客户端。
  StorageClient toClient();

  /// 统一提供“仅替换 baseDir / displayName”的客户端构造能力，避免测试代码按类型分支。
  StorageClient buildClient({
    String? baseDir,
    String? displayName,
  });
}

/// WebDAV 集成测试目标，复用现有 `WebDAVConfig` 结构。
class WebDavIntegrationTarget extends RemoteStorageIntegrationTarget {
  final WebDAVConfig config;
  @override
  final bool enabled;

  const WebDavIntegrationTarget(this.config, this.enabled);

  /// 复用现有 `WebDAVConfig` 的 JSON 结构，避免重复维护字段映射。
  factory WebDavIntegrationTarget.fromJson(Map<String, dynamic> json, bool enabled) {
    return WebDavIntegrationTarget(WebDAVConfig.fromJson(json), enabled);
  }

  @override
  RemoteStorageIntegrationKind get kind => RemoteStorageIntegrationKind.webdav;

  @override
  String get displayName => config.displayName;

  @override
  StorageClient toClient() => config.toClient();

  @override
  StorageClient buildClient({
    String? baseDir,
    String? displayName,
  }) {
    return config
        .copyWith(
          baseDir: baseDir,
          displayName: displayName,
        )
        .toClient();
  }
}

/// S3 / Aliyun OSS 集成测试目标，统一复用 `S3Config` 结构。
class S3IntegrationTarget extends RemoteStorageIntegrationTarget {
  final S3Config config;
  @override
  final bool enabled;

  const S3IntegrationTarget(this.config, this.enabled);

  /// 复用现有 `S3Config` 的 JSON 结构，保持和业务配置字段一致。
  factory S3IntegrationTarget.fromJson(Map<String, dynamic> json, bool enabled) {
    return S3IntegrationTarget(S3Config.fromJson(json), enabled);
  }

  @override
  RemoteStorageIntegrationKind get kind => RemoteStorageIntegrationKind.s3;

  @override
  String get displayName => config.displayName;

  @override
  StorageClient toClient() => config.toClient();

  @override
  StorageClient buildClient({
    String? baseDir,
    String? displayName,
  }) {
    return config
        .copyWith(
          baseDir: baseDir,
          displayName: displayName,
        )
        .toClient();
  }
}
