import 'dart:convert';

import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/utils/log.dart';

import 'data_cleanup_freq.dart';

const _tag = 'DataCleanupConfig';

class DataCleanupConfig {
  final List<String> tags;
  final List<String> devIds;
  final List<HistoryContentType> contentTypes;
  final bool saveTopData;
  final bool removeFiles;
  final bool autoClean;
  final DataCleanupFreq autoCleanFreq;
  final String? cron;
  final DateTime? lastCleanTime;
  final DateTime? nextCleanTime;
  final int? saveDays;

  const DataCleanupConfig({
    required this.tags,
    required this.devIds,
    required this.contentTypes,
    required this.saveTopData,
    required this.removeFiles,
    this.autoClean = false,
    this.autoCleanFreq = DataCleanupFreq.day,
    this.cron,
    this.lastCleanTime,
    this.nextCleanTime,
    this.saveDays,
  });

  DataCleanupConfig copyWith({
    List<String>? tags,
    List<String>? devIds,
    List<HistoryContentType>? contentTypes,
    bool? saveTopData,
    bool? removeFile,
    bool? autoClean,
    DataCleanupFreq? autoCleanFreq,
    String? cron,
    DateTime? lastCleanTime,
    DateTime? nextCleanTime,
    int? saveDays,
  }) {
    return DataCleanupConfig(
      tags: tags ?? this.tags,
      devIds: devIds ?? this.devIds,
      contentTypes: contentTypes ?? this.contentTypes,
      saveTopData: saveTopData ?? this.saveTopData,
      removeFiles: removeFile ?? removeFiles,
      autoClean: autoClean ?? this.autoClean,
      cron: cron ?? this.cron,
      autoCleanFreq: autoCleanFreq ?? this.autoCleanFreq,
      lastCleanTime: lastCleanTime ?? this.lastCleanTime,
      nextCleanTime: nextCleanTime ?? this.nextCleanTime,
      saveDays: saveDays ?? this.saveDays,
    );
  }

  /// 解析数据库中存储的清理配置，格式非法时返回 null。
  static DataCleanupConfig? tryParse(String json) {
    try {
      return DataCleanupConfig.fromJson(json);
    } catch (err, stack) {
      logger.error(_tag, err, stack);
      return null;
    }
  }

  factory DataCleanupConfig.fromJson(String json) {
    final map = jsonDecode(json);
    final freq = DataCleanupFreq.parse(map['autoCleanFreq']?.toString() ?? '');
    return DataCleanupConfig(tags: (map['tags'] as List<dynamic>).cast<String>(), devIds: (map['devIds'] as List<dynamic>).cast<String>(), contentTypes: (map['contentTypes'] as List<dynamic>).cast<String>().map(HistoryContentType.parse).where((e) => e != HistoryContentType.unknown).toList(), saveTopData: map['saveTopData'].toString().toBool(), removeFiles: map['removeFiles'].toString().toBool(), autoClean: map['autoClean'].toString().toBool(), cron: map['cron'], autoCleanFreq: freq == DataCleanupFreq.unknown ? DataCleanupFreq.day : freq, lastCleanTime: DateTime.tryParse(map['lastCleanTime']?.toString() ?? ''), nextCleanTime: DateTime.tryParse(map['nextCleanTime']?.toString() ?? ''), saveDays: map['saveDays']?.toString().toInt());
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
      'devIds': devIds,
      'contentTypes': contentTypes.map((e) => e.value).toList(),
      'saveTopData': saveTopData,
      'removeFiles': removeFiles,
      'autoClean': autoClean,
      'cron': cron,
      'autoCleanFreq': autoCleanFreq.name,
      'lastCleanTime': lastCleanTime?.format(),
      'nextCleanTime': nextCleanTime?.format(),
      'saveDays': saveDays,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
