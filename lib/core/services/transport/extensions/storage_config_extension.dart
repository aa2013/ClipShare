import 'package:clipshare/core/services/transport/storage/aliyun_oss_client.dart';
import 'package:clipshare/core/services/transport/storage/s3_client.dart';
import 'package:clipshare/core/services/transport/storage/storage_client.dart';
import 'package:clipshare/core/services/transport/storage/web_dav_client.dart';
import 'package:clipshare/shared/enums/obj_storage_type.dart';
import 'package:clipshare/shared/models/storage/s3_config.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';

extension S3ConfigExt on S3Config {
  /// 将配置转换为带完整运行时选项的存储客户端。
  StorageClient toClient() {
    final StorageClient client;
    if (type == ObjStorageType.aliyunOss) {
      client = AliyunOssClient(this);
    } else {
      client = S3Client(this);
    }
    return client;
  }
}

extension WebDAVConfigExt on WebDAVConfig {
  /// 将配置转换为带完整运行时选项的存储客户端。
  StorageClient toClient() {
    return WebDAVClient(this);
  }
}
