import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:get/get.dart';

enum BackupType {
  config("config.bin"),
  appInfo("appInfo.bin"),
  device("device.bin"),
  history("history.bin"),
  historyTag("historyTag.bin"),
  operationRecord("operationRecord.bin"),
  operationSync("operationSync.bin"),
  version("version.json");
  final String filename;
  const BackupType(this.filename);
  static BackupType? getValue(String name) => BackupType.values.firstWhereOrNull((e) => e.name == name);

  String get tr {
    switch (this) {
      case BackupType.config:
        return TranslationKey.backupTypeConfig.tr;
      case BackupType.appInfo:
        return TranslationKey.backupTypeAppInfo.tr;
      case BackupType.device:
        return TranslationKey.backupTypeDevice.tr;
      case BackupType.history:
        return TranslationKey.backupTypeHistory.tr;
      case BackupType.historyTag:
        return TranslationKey.backupTypeHistoryTag.tr;
      case BackupType.operationRecord:
        return TranslationKey.backupTypeOperationRecord.tr;
      case BackupType.operationSync:
        return TranslationKey.backupTypeOperationSync.tr;
      case BackupType.version:
        return TranslationKey.version.tr;
    }
  }
}
