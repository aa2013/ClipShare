import 'package:clipshare/app/data/enums/translation_key.dart';

enum BackupSource {
  unknown,
  local,
  s3,
  webdav;

  String get tr {
    switch (this) {
      case BackupSource.local:
        return TranslationKey.local.tr;
      case BackupSource.s3:
        return TranslationKey.s3.tr;
      case BackupSource.webdav:
        return 'WebDAV';
      case BackupSource.unknown:
        return 'unknown';
    }
  }
}
