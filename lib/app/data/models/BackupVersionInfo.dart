import 'dart:convert';

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
      map["dbVersion"],
      map["appVersion"],
      map["devName"],
      map["devId"],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "dbVersion": dbVersion,
      "appVersion": appVersion,
      "devName": devName,
      "devId": devId,
    };
  }
}
