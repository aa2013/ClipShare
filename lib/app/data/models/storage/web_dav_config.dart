import 'dart:convert';

class WebDavConfig {
  final String server;
  final String username;
  final String password;
  final String baseDir;
  final String displayName;

  WebDavConfig({
    required this.server,
    required this.username,
    required this.password,
    required this.baseDir,
    required this.displayName,
  });

  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      server: json["server"],
      username: json["username"],
      password: json["password"],
      baseDir: json["baseDir"],
      displayName: json["displayName"],
    );
  }

  WebDavConfig copyWith({
    String? displayName,
    String? server,
    String? username,
    String? password,
    String? baseDir,
    bool? enable,
  }) {
    return WebDavConfig(
      displayName: displayName ?? this.displayName,
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      baseDir: baseDir ?? this.baseDir,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "displayName": displayName,
      "server": server,
      "username": username,
      "password": password,
      "baseDir": baseDir,
    };
  }

  @override
  String toString() {
    final map = toJson();
    map["password"] = "***";
    return jsonEncode(map);
  }
}
