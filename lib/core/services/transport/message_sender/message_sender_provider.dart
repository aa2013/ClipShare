import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';
import 'package:clipshare/core/services/transport/message_sender/message_sender.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/core/settings/forward/forward_settings.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_way.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_sender_provider.g.dart';

@Riverpod(keepAlive: true)
class MessageSenderNotifier extends _$MessageSenderNotifier {
  static const tag = 'MessageSender';

  SessionNotifier get _session => ref.read(sessionProvider.notifier);

  StorageNotifier get _storage => ref.read(storageProvider.notifier);

  DeviceState get _deviceState => ref.read(deviceProvider).requireValue;

  ForwardSettings get _forwardSettings => ref.read(forwardSettingsProvider).requireValue;

  @override
  void build() {}

  MessageSender _getSender(TransportProtocol protocol) => protocol.isSocket ? _session : _storage;

  Future<void> sendToAll(MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) async {
    final enableForward = _forwardSettings.enable;
    final useStorageForward = ForwardWay.storageWays.contains(_forwardSettings.way);
    final noOnlineDevices = _deviceState.onlineAndPairedList.isEmpty;

    if (enableForward && useStorageForward && noOnlineDevices) {
      //如果无已配对的在线设备，且使用的存储服务，则直接写入存储不对设备发送通知
      await _storage.storeData(key, data);
      return;
    }
    //对在线设备发送数据
    final registry = _deviceState.registry;
    final onlineList = _deviceState.onlineList;
    for (var device in onlineList) {
      try {
        final protocol = registry.getProtocol(device.guid);
        if (protocol == null) {
          logger.warn(tag, 'skip send because transport protocol is unknown. devId=${device.guid}, msgType=${key.name}');
          continue;
        }
        await _getSender(protocol).sendData(device, key, data, onlyPaired);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  ///通过设备 id 发送数据
  Future<void> sendToDevice(String devId, MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) async {
    final registry = _deviceState.registry;
    final protocol = registry.getProtocol(devId);
    if (protocol == null) {
      logger.warn(tag, 'skip send because transport protocol is unknown. devId=$devId, msgType=${key.name}');
      return;
    }
    final onlineList = _deviceState.onlineList;
    final device = onlineList.firstWhereOrNull((device) => device.guid == devId);
    if (device == null) {
      logger.warn(tag, 'skip send because device is offline. devId=$devId, msgType=${key.name}');
      return;
    }
    try {
      await _getSender(protocol).sendData(device, key, data, onlyPaired);
    } catch (err, stack) {
      logger.error(tag, err, stack);
    }
  }
}
