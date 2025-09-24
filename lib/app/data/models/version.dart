import 'package:clipshare/app/utils/extensions/string_extension.dart';

class AppVersion {
  final String name;
  final String code;

  int get codeNum => code.toInt();

  const AppVersion(this.name, this.code);

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(json["name"], json["code"]);
  }

  @override
  String toString() {
    return "$name($code)";
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "code": code,
    };
  }

  bool operator >=(AppVersion other) {
    return codeNum >= other.codeNum;
  }

  bool operator <=(AppVersion other) {
    return codeNum <= other.codeNum;
  }

  bool operator >(AppVersion other) {
    return codeNum > other.codeNum;
  }

  bool operator <(AppVersion other) {
    return codeNum < other.codeNum;
  }

  int operator -(AppVersion other) {
    return codeNum - other.codeNum;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppVersion && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
