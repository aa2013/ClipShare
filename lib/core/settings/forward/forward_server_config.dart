import 'dart:convert';

import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';

const _tag = 'ForwardServerConfig';

class ForwardServerConfig {
  String host;
  int port;
  String? key;

  String get server => '$host:$port';

  ForwardServerConfig({
    required this.host,
    required this.port,
    this.key,
  });

  factory ForwardServerConfig.fromJson(Map<String, dynamic> data) {
    String? key = data.containsKey('key')
        ? data['key'] == ''
            ? null
            : data['key']
        : null;
    return ForwardServerConfig(
      host: data['host'],
      port: data['port'],
      key: key,
    );
  }

  /// 解析数据库中存储的中转服务器配置。
  ///
  /// [value] 为 JSON 字符串或旧版本的 "host:port" 格式，解析失败返回 null。
  static ForwardServerConfig? tryParse(String value) {
    try {
      if (value.startsWith('{')) {
        return ForwardServerConfig.fromJson(jsonDecode(value));
      } else {
        final [host, port] = value.split(':');
        return ForwardServerConfig(host: host, port: port.toInt());
      }
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'key': key,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
