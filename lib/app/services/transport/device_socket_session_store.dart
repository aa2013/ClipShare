import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';

/// 当前在线设备的 Socket 会话，封装业务层需要读取的 ready 后状态。
class DeviceSocketSession {
  /// 远端设备信息，来自 SecureSocketClient 已完成的设备握手。
  final DevInfo dev;

  /// 当前被业务层采用的 ready Socket；替换和删除都必须校验对象身份。
  final SecureSocketClient socket;

  /// 双方都确认已配对时才为 true，发送同步数据时会以它作为过滤条件。
  bool isPaired;

  /// 远端要求的最低兼容版本，ready 握手完成后必须可用。
  AppVersion minVersion;

  /// 远端当前应用版本，发送业务数据前用于兼容性判断。
  AppVersion version;

  /// 会话正在关闭时置为 true，避免调试时误判为仍可发送。
  bool closing = false;

  DeviceSocketSession({
    required this.dev,
    required this.socket,
    required this.isPaired,
    required this.minVersion,
    required this.version,
  });

}

/// 只维护 devId 到当前 ready 会话的映射，不发起连接也不触发业务通知。
class DeviceSocketSessionStore {
  /// 当前被业务层认可的在线会话表，key 永远是 devId，不能使用 DevInfo 实例。
  final Map<String, DeviceSocketSession> _sessions = {};

  /// 按 devId 获取当前会话，调用方不能直接接触内部 Map。
  DeviceSocketSession? get(String devId) {
    return _sessions[devId];
  }

  /// 登记一个已经完成握手的 ready 会话；调用方负责先完成探活和旧会话关闭。
  void put(DeviceSocketSession session) {
    _sessions[session.dev.guid] = session;
  }

  /// 当前会话数量，用于心跳任务判断是否还有 Socket 需要保活。
  bool get isEmpty => _sessions.isEmpty;

  /// 当前在线设备 id 快照，避免遍历过程中被关闭流程修改。
  List<String> get devIds => _sessions.keys.toList(growable: false);

  /// 判断设备是否在线；requiredPaired 为 true 时要求双方都已配对。
  bool isOnline(String devId, {required bool requiredPaired}) {
    final session = _sessions[devId];
    if (session == null) {
      return false;
    }
    return !requiredPaired || session.isPaired;
  }

  /// 判断传入 client 是否仍是当前会话，防止旧回调误删新连接。
  bool isCurrent(String devId, SecureSocketClient client) {
    return identical(_sessions[devId]?.socket, client);
  }

  /// 仅当 client 仍是当前会话时删除并返回它，所有关闭入口都必须走这里。
  DeviceSocketSession? removeIfCurrent(
    String devId,
    SecureSocketClient client,
  ) {
    final current = _sessions[devId];
    if (current == null || !identical(current.socket, client)) {
      return null;
    }
    _sessions.remove(devId);
    return current;
  }

  /// 主动断开时按 devId 删除当前会话；调用方随后仍需关闭底层 Socket。
  DeviceSocketSession? remove(String devId) {
    return _sessions.remove(devId);
  }

  /// 根据 Socket 身份查找当前会话，用于 onDone/onError 的旧回调过滤。
  MapEntry<String, DeviceSocketSession>? findBySocket(
    SecureSocketClient client,
  ) {
    for (final entry in _sessions.entries) {
      if (identical(entry.value.socket, client)) {
        return entry;
      }
    }
    return null;
  }

  /// 返回当前会话快照，调用方可以安全遍历并逐个关闭。
  List<DeviceSocketSession> snapshot() {
    return _sessions.values.toList(growable: false);
  }

  /// 清空所有会话引用，通常只在服务释放后使用。
  void clear() {
    _sessions.clear();
  }
}
