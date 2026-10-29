import 'dart:convert';

import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/version.dart';

///应用更新日志
class UpdateLog {
  ///适用的平台（windows/linux/android/ios/mac/all）
  final String platform;

  ///发布日期
  final DateTime date;

  ///版本号
  final AppVersion version;

  ///更新说明
  final String desc;

  ///下载地址
  final String downloadUrl;

  const UpdateLog({
    required this.platform,
    required this.date,
    required this.version,
    required this.desc,
    required this.downloadUrl,
  });

  factory UpdateLog.fromJson(Map<String, dynamic> json) {
    final versionCode = json['version']['code'];
    final versionName = json['version']['name'];
    return UpdateLog(
      platform: json['platform'],
      date: DateTime.parse(json['date']),
      version: AppVersion(versionName, versionCode),
      desc: json['desc'],
      downloadUrl: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'date': date.format(),
      'version': version.toString(),
      'desc': desc,
      'downloadUrl': downloadUrl,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
