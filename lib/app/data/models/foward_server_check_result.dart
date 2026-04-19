import 'dart:convert';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';

class ForwardServerCheckResult {
  final bool success;
  final String? version;
  final bool unlimited;
  final int? deviceLimit;

  //KB/s
  final double? fileSyncRate;
  final bool fileSyncNotAllowed;
  final int lifeSpan;
  final int rate;
  final double remaining;
  final bool isPublicServer;
  final String? remark;

  final String originData;
  final bool unknown;

  ForwardServerCheckResult._({
    required this.success,
    required this.isPublicServer,
    required this.version,
    required this.unlimited,
    required this.deviceLimit,
    required this.fileSyncRate,
    required this.fileSyncNotAllowed,
    required this.lifeSpan,
    required this.rate,
    required this.remaining,
    required this.remark,
    required this.originData,
    required this.unknown,
  });

  factory ForwardServerCheckResult.fromJson(Map<String, dynamic> json) {
    final unknown = !json.containsKey("result");
    final version = json["version"]?.toString();
    bool success = false;
    bool unlimited = false;
    bool isPublicServer = false;
    int? deviceLimit;
    double? fileSyncRate;
    bool fileSyncNotAllowed = false;
    int lifeSpan = -1;
    int rate = -1;
    double remaining = 0;
    if (!unknown) {
      success = json["result"] == "success";
      unlimited = json.containsKey("unlimited");
      if (!unlimited) {
        final deviceLimitStr = json["deviceLimit"]?.toString();
        if (deviceLimitStr == null) {
          isPublicServer = true;
          fileSyncRate = json["fileSyncRate"]?.toString().toDouble();
          if (fileSyncRate == null) {
            fileSyncNotAllowed = json.containsKey("fileSyncNotAllowed");
          }
        } else {
          if (deviceLimitStr == '∞') {
            deviceLimit = -1;
          } else {
            deviceLimit = deviceLimitStr.toInt();
          }

          String lifeSpanStr = json["lifeSpan"];
          if (lifeSpanStr == "∞") {
            lifeSpan = -1;
          } else {
            lifeSpan = lifeSpanStr.toInt();
          }

          String rateStr = json["rate"];
          if (rateStr == "∞") {
            rate = -1;
          } else {
            rate = rate.toInt();
          }

          String remainingStr = json["remaining"];
          if (remainingStr == "-1") {
            remaining = -1;
          } else if (remainingStr != "0") {
            remaining = remainingStr.toDouble() / (24 * 60 * 60);
          } else {
            remaining = 0;
          }
        }
      }
    }
    return ForwardServerCheckResult._(
      originData: jsonEncode(json),
      success: success,
      unknown: unknown,
      isPublicServer: isPublicServer,
      version: version,
      unlimited: unlimited,
      deviceLimit: deviceLimit,
      fileSyncRate: fileSyncRate,
      fileSyncNotAllowed: fileSyncNotAllowed,
      lifeSpan: lifeSpan,
      rate: rate,
      remaining: remaining,
      remark: json["remark"]?.toString(),
    );
  }

  @override
  String toString() {
    if (unknown) {
      return originData;
    }
    if (!success) {
      return TranslationKey.connectFailed.tr;
    }
    final tooLowerVersion = ForwardSocketClient.lessThan114(version);
    final buffer = StringBuffer();
    if (unlimited) {
      buffer.writeln(TranslationKey.forwardServerUnlimitedDevices.tr);
    } else {
      if (deviceLimit == null) {
        buffer.writeln(TranslationKey.publicForwardServer.tr);
        if (fileSyncRate != null) {
          buffer.write(TranslationKey.forwardServerSyncFileRateLimit.tr);
          buffer.write(": ");
          buffer.writeln("$fileSyncRate KB/s");
        } else if (fileSyncNotAllowed) {
          buffer.writeln(TranslationKey.forwardServerCannotSyncFile.tr);
        } else {
          buffer.writeln(TranslationKey.forwardServerNoLimits.tr);
        }
      } else {
        buffer.write(TranslationKey.forwardServerDeviceConnectionLimit.tr);
        buffer.write(" ");
        if (deviceLimit == -1) {
          buffer.writeln(TranslationKey.noLimits.tr);
        } else {
          buffer.write(deviceLimit);
          buffer.write(" ");
          buffer.writeln(TranslationKey.deviceUnit.tr);
        }

        buffer.write(TranslationKey.forwardServerLifeSpan.tr);
        buffer.write(" ");
        if (lifeSpan == -1) {
          buffer.writeln(TranslationKey.noLimits.tr);
        } else {
          buffer.write(lifeSpan);
          buffer.write(" ");
          buffer.writeln(TranslationKey.day.tr);
        }

        buffer.write(TranslationKey.forwardServerRateLimit.tr);
        buffer.write(" ");
        if (rate == -1) {
          buffer.writeln(TranslationKey.noLimits.tr);
        } else {
          buffer.write(rate);
          buffer.write(" ");
          buffer.writeln("KB/s");
        }

        buffer.write(TranslationKey.forwardServerRemainingTime.tr);
        buffer.write(" ");
        if (remaining == -1) {
          buffer.writeln(TranslationKey.forwardServerKeyNotStarted.tr);
        } else if (remaining != 0) {
          buffer.write(remaining.toStringAsFixed(2));
          buffer.write(" ");
          buffer.writeln(TranslationKey.day.tr);
        } else {
          buffer.writeln(TranslationKey.exhausted.tr);
        }

        if (remark.isNotNullAndEmpty) {
          buffer.write(TranslationKey.tips.tr);
          buffer.write(": ");
          buffer.writeln(remark);
        }
      }
    }
    if (tooLowerVersion) {
      buffer.write(TranslationKey.tips.tr);
      buffer.write(": ");
      buffer.writeln(TranslationKey.forwardServer114VersionTip.tr);
    }
    return buffer.toString();
  }
}
