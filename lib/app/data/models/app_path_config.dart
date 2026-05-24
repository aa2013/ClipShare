import 'dart:convert';

class AppPathConfig {
  final String? fileStorePath;
  final String? databasePath;

  const AppPathConfig({required this.fileStorePath, required this.databasePath});

  factory AppPathConfig.fromJson(Map<String, dynamic> json) {
    return AppPathConfig(
      fileStorePath: json["fileStorePath"],
      databasePath: json["databasePath"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fileStorePath": fileStorePath,
      "databasePath": databasePath,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
