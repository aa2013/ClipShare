import 'dart:ui';

import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'forward_server_status.dart';
import 'forward_way.dart';

part 'forward_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ForwardSettings> forwardSettings(Ref ref) async {
  return const ForwardSettings();
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
