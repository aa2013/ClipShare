
import 'dart:convert';

import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/models/storage/s3_config.dart';
import 'package:clipshare/shared/models/storage/web_dav_config.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'forward_server_config.dart';
import 'forward_server_status.dart';
import 'forward_way.dart';

part 'forward_settings_provider.g.dart';

const _tag = 'forwardSettingsProvider';

/// 读取中转相关配置。
@Riverpod(keepAlive: true)
Future<ForwardSettings> forwardSettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return ForwardSettings(
    enable: await cfg.getConfigByKey(.enableForward, false),
    way: await cfg.getConfigByKey(
      .forwardWay,
      .none,
      convert: _parseForwardWay,
    ),
    serverConfig: await cfg.getConfigByKey(
      .forwardServer,
      null,
      convert: ForwardServerConfig.tryParse,
    ),
    s3Config: await cfg.getConfigByKey(.s3Config, null, convert: _parseS3Config),
    webdavConfig: await cfg.getConfigByKey(.webdavConfig, null, convert: _parseWebDavConfig),
    notificationServer: await cfg.getConfigByKey(.notificationServer, defaultNotificationServer),
  );
}

/// 解析中转方式，非法配置回退到未启用状态。
ForwardWay _parseForwardWay(String value) {
  try {
    return ForwardWay.values.byName(value);
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return ForwardWay.none;
  }
}

/// 解析 S3 配置，格式非法时视为未配置。
S3Config? _parseS3Config(String value) {
  try {
    return S3Config.fromJson(jsonDecode(value));
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return null;
  }
}

/// 解析 WebDAV 配置，格式非法时视为未配置。
WebDAVConfig? _parseWebDavConfig(String value) {
  try {
    return WebDAVConfig.fromJson(jsonDecode(value));
  } catch (err, stack) {
    logger.error(_tag, err, stack);
    return null;
  }
}

/// Returns the icon used for one forward transport option.
IconData forwardWayIcon(ForwardWay way) {
  switch (way) {
    case ForwardWay.server:
      return Icons.cloud_queue_rounded;
    case ForwardWay.webdav:
      return Icons.dns_rounded;
    case ForwardWay.s3:
      return Icons.inventory_2_outlined;
    case ForwardWay.none:
      return Icons.cloud_off_rounded;
  }
}

/// Returns the visible label for one forward transport option.
String forwardWayLabel(ForwardWay way) {
  switch (way) {
    case ForwardWay.server:
      return TranslationKey.forwardServer.tr;
    case ForwardWay.webdav:
      return 'WebDAV';
    case ForwardWay.s3:
      return TranslationKey.s3.tr;
    case ForwardWay.none:
      return TranslationKey.none.tr;
  }
}

/// Builds the compact status text shown on the promoted forward overview card.
String forwardOverviewStatusText({
  required ForwardWay way,
  required bool enabled,
  required ForwardServerStatus status,
}) {
  if (way == ForwardWay.none || !enabled) {
    return TranslationKey.settingsOverviewForwardClosed.tr;
  }
  return status.tr;
}

/// Chooses the promoted forward overview card color from its current status.
Color forwardOverviewTone({
  required ForwardWay way,
  required bool enabled,
  required ForwardServerStatus status,
}) {
  if (way == ForwardWay.none || !enabled) {
    return Colors.blueGrey;
  }
  switch (status) {
    case ForwardServerStatus.initializing:
      return Colors.amber;
    case ForwardServerStatus.connected:
      return Colors.green;
    case ForwardServerStatus.connecting:
      return Colors.blue;
    case ForwardServerStatus.disconnected:
      return Colors.orange;
  }
}
