import 'dart:convert';

import 'package:clipshare/app/data/enums/clean_data_freq.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';

class CleanDataConfig {
  final List<String> tags;
  final List<String> devIds;
  final List<HistoryContentType> contentTypes;
  final bool saveTopData;
  final bool removeFiles;
  final bool autoClean;
  final CleanDataFreq autoCleanFreq;
  final String? cron;
  final DateTime? lastCleanTime;
  final DateTime? nextCleanTime;
  final int? saveDays;

  const CleanDataConfig({
    required this.tags,
    required this.devIds,
    required this.contentTypes,
    required this.saveTopData,
    required this.removeFiles,
    this.autoClean = false,
    this.autoCleanFreq = CleanDataFreq.day,
    this.cron,
    this.lastCleanTime,
    this.nextCleanTime,
    this.saveDays,
  });

  CleanDataConfig copyWith({
    List<String>? tags,
    List<String>? devIds,
    List<HistoryContentType>? contentTypes,
    bool? saveTopData,
    bool? removeFile,
    bool? autoClean,
    CleanDataFreq? autoCleanFreq,
    String? cron,
    DateTime? lastCleanTime,
    DateTime? nextCleanTime,
    int? saveDays,
  }) {
    return CleanDataConfig(
      tags: tags ?? this.tags,
      devIds: devIds ?? this.devIds,
      contentTypes: contentTypes ?? this.contentTypes,
      saveTopData: saveTopData ?? this.saveTopData,
      removeFiles: removeFile ?? this.removeFiles,
      autoClean: autoClean ?? this.autoClean,
      cron: cron ?? this.cron,
      autoCleanFreq: autoCleanFreq ?? this.autoCleanFreq,
      lastCleanTime: lastCleanTime ?? this.lastCleanTime,
      nextCleanTime: nextCleanTime ?? this.nextCleanTime,
      saveDays: saveDays ?? this.saveDays,
    );
  }

  factory CleanDataConfig.fromJson(String json) {
    final map = jsonDecode(json);
    final freq = CleanDataFreq.parse(map['autoCleanFreq']?.toString() ?? "");
    return CleanDataConfig(
      tags: (map['tags'] as List<dynamic>).cast<String>(),
      devIds: (map['devIds'] as List<dynamic>).cast<String>(),
      contentTypes: (map['contentTypes'] as List<dynamic>).cast<String>().map(HistoryContentType.parse).where((e) => e != HistoryContentType.unknown).toList(),
      saveTopData: map['saveTopData'].toString().toBool(),
      removeFiles: map['removeFiles'].toString().toBool(),
      autoClean: map['autoClean'].toString().toBool(),
      cron: map['cron'],
      autoCleanFreq: freq == CleanDataFreq.unknown ? CleanDataFreq.day : freq,
      lastCleanTime: DateTime.tryParse(map['lastCleanTime']?.toString() ?? ""),
      nextCleanTime: DateTime.tryParse(map['nextCleanTime']?.toString() ?? ""),
      saveDays: map['saveDays']?.toString().toInt()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tags": tags,
      "devIds": devIds,
      "contentTypes": contentTypes.map((e)=>e.value).toList(),
      "saveTopData": saveTopData,
      "removeFiles": removeFiles,
      "autoClean": autoClean,
      "cron": cron,
      "autoCleanFreq": autoCleanFreq.name,
      "lastCleanTime": lastCleanTime?.format(),
      "nextCleanTime": nextCleanTime?.format(),
      "saveDays": saveDays,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
