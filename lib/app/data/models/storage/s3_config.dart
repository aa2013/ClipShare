import 'dart:convert';

import 'package:clipshare/app/data/enums/obj_storage_type.dart';

class S3Config {
  final ObjStorageType type;
  final String endPoint;
  final String accessKey;
  final String secretKey;
  final String bucketName;
  final String? region;
  final String displayName;
  final String baseDir;
  final bool pathStyle;

  S3Config({
    required this.endPoint,
    required this.accessKey,
    required this.secretKey,
    required this.bucketName,
    required this.displayName,
    required this.baseDir,
    required this.type,
    this.region,
    this.pathStyle = false,
  });

  factory S3Config.fromJson(Map<String, dynamic> json) {
    return S3Config(
      endPoint: json['endPoint'],
      accessKey: json['accessKey'],
      secretKey: json['secretKey'],
      bucketName: json['bucketName'],
      displayName: json['displayName'],
      baseDir: json['baseDir'],
      type: ObjStorageType.values.byName(json['type']),
      region: json['region'],
      pathStyle: json['pathStyle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "endPoint": endPoint,
      "accessKey": accessKey,
      "secretKey": secretKey,
      "bucketName": bucketName,
      "displayName": displayName,
      "baseDir": baseDir,
      "region": region,
      "type": type.name,
      "pathStyle": pathStyle,
    };
  }

  @override
  String toString() {
    final map = toJson();
    map["secretKey"] = "***";
    return jsonEncode(map);
  }

  S3Config copyWith({
    String? endPoint,
    String? accessKey,
    String? secretKey,
    String? bucketName,
    String? displayName,
    String? baseDir,
    ObjStorageType? type,
    String? region,
    bool? pathStyle,
  }) {
    return S3Config(
      endPoint: endPoint ?? this.endPoint,
      accessKey: accessKey ?? this.accessKey,
      secretKey: secretKey ?? this.secretKey,
      bucketName: bucketName ?? this.bucketName,
      displayName: displayName ?? this.displayName,
      baseDir: baseDir ?? this.baseDir,
      type: type ?? this.type,
      region: region ?? this.region,
      pathStyle: pathStyle ?? this.pathStyle,
    );
  }
}
