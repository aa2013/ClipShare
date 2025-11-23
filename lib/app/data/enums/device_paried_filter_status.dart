import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum DevicePairedFilterStatus {
  all,
  online,
  offline;

  IconData get icon {
    switch (this) {
      case DevicePairedFilterStatus.all:
        return Icons.all_inclusive;
      case DevicePairedFilterStatus.online:
        return Icons.wifi_outlined;
      case DevicePairedFilterStatus.offline:
        return Icons.wifi_off_outlined;
    }
  }

  String get tr {
    switch (this) {
      case DevicePairedFilterStatus.all:
        return TranslationKey.all.tr;
      case DevicePairedFilterStatus.online:
        return TranslationKey.online.tr;
      case DevicePairedFilterStatus.offline:
        return TranslationKey.offline.tr;
    }
  }
}
