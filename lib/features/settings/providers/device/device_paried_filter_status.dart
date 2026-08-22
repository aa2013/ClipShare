import 'package:clipshare/core/utils/log.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum DevicePairedStatusFilter {
  all,
  online,
  offline
  ;

  IconData get icon {
    switch (this) {
      case DevicePairedStatusFilter.all:
        return Icons.all_inclusive;
      case DevicePairedStatusFilter.online:
        return Icons.wifi_outlined;
      case DevicePairedStatusFilter.offline:
        return Icons.wifi_off_outlined;
    }
  }

  String get tr {
    switch (this) {
      case DevicePairedStatusFilter.all:
        return TranslationKey.all.tr;
      case DevicePairedStatusFilter.online:
        return TranslationKey.online.tr;
      case DevicePairedStatusFilter.offline:
        return TranslationKey.offline.tr;
    }
  }

  static DevicePairedStatusFilter parse(String value) => DevicePairedStatusFilter.values.firstWhere(
    (e) => e.name.toUpperCase() == value.toUpperCase(),
    orElse: () {
      logger.debug("DevicePairedStatusFilter", "key '$value' unknown");
      return DevicePairedStatusFilter.all;
    },
  );
}
