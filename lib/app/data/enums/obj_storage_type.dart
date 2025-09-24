import 'package:clipshare/app/data/enums/translation_key.dart';

enum ObjStorageType {
  aliyunOss,
  s3;

  String get displayName {
    switch (this) {
      case ObjStorageType.aliyunOss:
        return TranslationKey.aliyunOss.tr;
      case ObjStorageType.s3:
        return TranslationKey.standardS3Protocol.tr;
    }
    return "Unknown";
  }
}
