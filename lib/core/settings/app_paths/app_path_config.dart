import 'dart:convert';

class CustomPathConfig {
  final String? fileStorePath;
  final String? databasePath;

  const CustomPathConfig({required this.fileStorePath, required this.databasePath});

  factory CustomPathConfig.fromJson(Map<String, dynamic> json) {
    return CustomPathConfig(
      fileStorePath: json['fileStorePath'],
      databasePath: json['databasePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileStorePath': fileStorePath,
      'databasePath': databasePath,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
