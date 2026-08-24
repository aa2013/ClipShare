import 'package:clipshare/core/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_database.dart';

export '../app_database.dart' show History;

/// 构造空历史对象，供缺失数据同步流程作为删除占位使用。
History emptyHistory({
  int id = 0,
  int uid = 0,
  String time = '',
  String content = '',
  String type = '',
  String devId = '',
  bool top = false,
  bool sync = false,
  int size = 0,
  String? updateTime,
  String? source,
  String? extracted,
}) {
  return History(
    id: id,
    uid: uid,
    time: time,
    content: content,
    extracted: extracted,
    type: type,
    devId: devId,
    top: top,
    sync: sync,
    size: size,
    updateTime: updateTime,
    source: source,
  );
}

History simpleHistory(Ref ref, HistoryContentType type, String content) {
  final idGenerator = ref.read(idProvider);
  final localDeviceInfo = ref.read(localDeviceInfoProvider).requireValue;
  return History(
    id: idGenerator.nextId(),
    uid: 0,
    time: DateTime.now().toString(),
    content: content,
    type: type.value,
    devId: localDeviceInfo.baseDeviceInfo.id,
    top: false,
    sync: false,
    size: content.length,
    extracted: null,
  );
}

/// 将窗口通信中的 JSON 列表还原为 Drift 历史数据类。
List<History> historyListFromJson(List<dynamic> jsonList) {
  return jsonList.map((map) => History.fromJson((map as Map).cast<String, dynamic>())).toList(growable: true);
}
