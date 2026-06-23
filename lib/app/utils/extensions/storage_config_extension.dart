import 'package:clipshare/app/data/enums/obj_storage_type.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/handlers/storage/aliyun_oss_client.dart';
import 'package:clipshare/app/handlers/storage/s3_client.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';

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
