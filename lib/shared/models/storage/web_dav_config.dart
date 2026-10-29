import 'dart:convert';

class WebDAVConfig {
  final String server;
  final String username;
  final String password;
  final String baseDir;
  final String displayName;
  final String? userAgent;

  const WebDAVConfig({
    required this.server,
    required this.username,
    required this.password,
    required this.baseDir,
    required this.displayName,
    this.userAgent,
  });

  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    return WebDAVConfig(
      server: json['server'],
      username: json['username'],
      password: json['password'],
      baseDir: json['baseDir'],
      displayName: json['displayName'],
      userAgent: json['userAgent'],
    );
  }

  WebDAVConfig copyWith({
    String? displayName,
    String? server,
    String? username,
    String? password,
    String? baseDir,
    String? userAgent,
    bool? enable,
  }) {
    return WebDAVConfig(
      displayName: displayName ?? this.displayName,
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      baseDir: baseDir ?? this.baseDir,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'server': server,
      'username': username,
      'password': password,
      'baseDir': baseDir,
      'userAgent': userAgent,
    };
  }

  @override
  String toString() {
    final map = toJson();
    map.remove('server');
    map.remove('username');
    map.remove('password');
    return jsonEncode(map);
  }
}
