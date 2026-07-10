import 'package:dio/dio.dart';

class NotificationServerUtil {
  const NotificationServerUtil._();

  /// 将通知服务的 ws/wss 地址转换为版本检查接口地址。
  static Uri buildCheckVersionUri(String server) {
    final serverUri = Uri.parse(_trimTrailingSlash(server.trim()));
    final scheme = switch (serverUri.scheme) {
      'ws' => 'http',
      'wss' => 'https',
      _ => serverUri.scheme,
    };
    final path = serverUri.path.isEmpty ? '/checkVersion' : '${serverUri.path}/checkVersion';
    return serverUri.replace(scheme: scheme, path: path, query: '', fragment: '');
  }

  static String _trimTrailingSlash(String value) {
    var result = value;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// 请求通知服务版本号；调用方决定失败后的业务处理。
  static Future<String> getVersion(
    String server, {
    Dio? dio,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = dio ?? Dio();
    final resp = await client.getUri<String>(
      buildCheckVersionUri(server),
      options: Options(
        responseType: ResponseType.plain,
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
    final version = (resp.data ?? '').trim();
    if (version.isEmpty) {
      throw Exception('notification server version is empty');
    }
    return version;
  }
}
