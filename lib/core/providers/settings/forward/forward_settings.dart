import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/providers/settings/forward/forward_server_config.dart';
import 'package:clipshare/core/providers/settings/forward/s3_config.dart';

import 'forward_way.dart';
import 'web_dav_config.dart';

class ForwardSettings {
  ///是否启用中转
  final bool enable;

  ///中转方式
  final ForwardWay way;

  ///中转服务器配置
  final ForwardServerConfig? serverConfig;

  ///s3配置
  final S3Config? s3Config;

  ///webdav配置
  final WebDAVConfig? webdavConfig;

  ///通知服务配置
  final String notificationServer;

  ///本机是否启用 webdav 中转
  bool get enableWebDAV => way == ForwardWay.webdav;

  ///本机是否启用 对象存储 中转
  bool get enableS3 => way == ForwardWay.s3;

  ///本机是否启用 存储 进行中转
  bool get enableStorageSync => enableWebDAV || enableS3;

  const ForwardSettings({
    this.enable = false,
    this.way = ForwardWay.none,
    this.notificationServer = defaultNotificationServer,
    this.serverConfig,
    this.s3Config,
    this.webdavConfig,
  });
}
