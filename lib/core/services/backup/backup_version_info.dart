import 'dart:convert';

/// 备份包版本信息，写入备份包内的 version.json
class BackupVersionInfo {
  final int dbVersion;
  final int appVersion;
  final String devName;
  final String devId;

  const BackupVersionInfo(
    this.dbVersion,
    this.appVersion,
    this.devName,
    this.devId,
  );

  factory BackupVersionInfo.fromJson(Map<String, dynamic> map) {
    return BackupVersionInfo(
      map['dbVersion'],
      map['appVersion'],
      map['devName'],
      map['devId'],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'dbVersion': dbVersion,
      'appVersion': appVersion,
      'devName': devName,
      'devId': devId,
    };
  }
}
