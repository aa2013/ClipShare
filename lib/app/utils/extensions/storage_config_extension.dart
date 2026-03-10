import 'package:clipshare/app/data/enums/obj_storage_type.dart';
import 'package:clipshare/app/data/models/storage/s3_config.dart';
import 'package:clipshare/app/data/models/storage/web_dav_config.dart';
import 'package:clipshare/app/handlers/storage/aliyun_oss_client.dart';
import 'package:clipshare/app/handlers/storage/s3_client.dart';
import 'package:clipshare/app/handlers/storage/storage_client.dart';
import 'package:clipshare/app/handlers/storage/web_dav_client.dart';

extension S3ConfigExt on S3Config {
  StorageClient toClient() {
    if (type == ObjStorageType.aliyunOss) {
      return AliyunOssClient(this);
    } else {
      return S3Client(this);
    }
  }
}

extension WebDAVConfigExt on WebDAVConfig {
  StorageClient toClient() {
    return WebDAVClient(this);
  }
}
