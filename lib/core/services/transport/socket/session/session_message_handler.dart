part of 'session_provider.dart';

const sessionTag = 'SessionNotifier';

/// 数据同步处理：协议解析交给分发层
void _onSyncMsg(Ref ref, MessageData msg, SyncSource source) {
  final dispatcher = ref.read(syncReceiveDispatcherProvider.notifier);
  if (msg.key == .ackSync) {
    dispatcher.handleAckSync(msg);
    return;
  }
  dispatcher.handleSync(msg, source: source);
}

/// 缺失数据同步：剥掉批量补数的进度外壳后按普通同步消息处理。
void _onMissingData(Ref ref, MessageData msg) {
  final copyMsg = msg.copy();
  final data = msg.data['data'] as Map<dynamic, dynamic>;
  copyMsg.data = data.cast<String, dynamic>();
  //上报补数进度事件
  final seq = msg.data['seq'];
  final total = msg.data['total'];
  if (seq is int && total is int) {
    final syncNotifier = ref.read(messageSyncProvider.notifier);
    syncNotifier.emitMissingDataBatch(msg.send.guid, seq, total);
  }
  _onSyncMsg(ref, copyMsg, SyncSource.missingData);
}

/// 请求缺失数据：把本机尚未同步到请求方的操作记录补推过去。
Future<void> _onRequestMissingData(Ref ref, MessageData msg) async {
  final syncedAppIds = ((msg.data['appIds'] ?? []) as List<dynamic>).cast<String>();
  final localDeviceInfo = ref.read(localDeviceInfoProvider).requireValue;
  final localDevId = localDeviceInfo.baseDeviceInfo.guid;
  final syncPush = ref.read(syncPushProvider.notifier);
  await syncPush.sendMissingData(
    targetDev: msg.send,
    fromDevId: localDevId,
    syncedAppIds: syncedAppIds,
  );
}

/// 文件传输控制消息：解析控制信息后反连发送端临时端口接收文件流
Future<void> _onReceiveFile(Ref ref, SecureSocketClient client, MessageData msg) async {
  final data = DirectFileMsg.fromJson(msg.data);
  final receiver = ref.read(fileReceiverProvider.notifier);
  try {
    await receiver.receiveDirect(
      ip: client.ip,
      port: data.port,
      size: data.size,
      fileName: data.fileName,
      devId: msg.send.guid,
      fileId: data.fileId,
    );
  } catch (err, stack) {
    logger.debug(
      sessionTag,
      'receive file failed. ip:${client.ip}, port:${data.port}, file:${data.fileName}. $err $stack',
    );
  }
}

/// 请求app信息
Future<void> _onRequestAppInfo(SessionNotifier self, Ref ref, MessageData msg) async {
  final appId = msg.data['appId'];
  logger.debug(sessionTag, 'await loading source future');
  final clipboardSource = await ref.read(clipboardSourceProvider.future);
  logger.debug(sessionTag, 'loaded source');
  final appInfo = clipboardSource.getAppInfoByAppId(appId);
  if (appInfo == null) {
    logger.debug(sessionTag, 'not found app info $appId');
    return;
  }
  logger.debug(sessionTag, 'found app info $appId');
  await self.sendData(msg.send, .appInfo, appInfo.toJson());
}

/// 收到 app 信息
Future<void> _onReceiveAppInfo(SessionNotifier self, Ref ref, MessageData msg) async {
  final sourceAppInfo = AppInfo.fromJson(msg.data);
  final clipboardSourceNotifier = ref.read(clipboardSourceProvider.notifier);
  final appInfo = sourceAppInfo.id == 0 ? sourceAppInfo.copyWith(id: sourceAppInfo.appId.hash64) : sourceAppInfo;
  await clipboardSourceNotifier.addOrUpdate(appInfo);
}

///请求配对设备
///
/// 发起方为 [msg.send]，按设备 id 独立管理弹窗与验证码。
/// 同一设备重复发起视为重新请求：先撤销旧弹窗与旧通知，再覆盖验证码重新弹出。
Future<void> _requestPairingDevice(SessionNotifier self, MessageData msg) async {
  final context = navigatorKey.currentContext!;
  final dev = msg.send;
  // 撤销该设备旧请求并等待旧弹窗真正移除
  await self._closePairingRequest(dev.guid);
  final random = Random();
  int code = 100000 + random.nextInt(900000);
  self._deviceParingCodeNotifier.addCode(dev.guid, CryptoUtil.toMD5(code));
  //发送通知
  final notifyId = await self._notifyNotifier.notify(
    content: '${TranslationKey.devicePairingRequestNotificationContent.tr}: $code',
    key: 'dev-pairing-${dev.guid}',
  );
  if (!context.mounted) {
    return;
  }
  await _showPairingRequestDialog(self, context, dev, code, notifyId);
}

/// 展示配对请求弹窗
///
/// [code] 为已生成的明文验证码，展示给本机用户输入到发起方；
/// [notifyId] 为携带验证码的系统通知 id，供验证成功/取消时撤销。
Future<void> _showPairingRequestDialog(SessionNotifier self, BuildContext context, BaseDeviceInfo dev, int code, int? notifyId) async {
  final dlgCtl = dialogManager.open(
    context,
    AlertDialog(
      title: Text(TranslationKey.devicePairingRequestDialogTitle.tr),
      content: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(TranslationKey.pairingCodeDialogContent.trParams({'devName': dev.name})),
            const SizedBox(
              height: 10,
            ),
            Text(
              code.toString().split('').join('  '),
              style: const TextStyle(fontSize: 30),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            unawaited(self.cancelPairing(dev));
          },
          child: Text(TranslationKey.cancelCurrentPairing.tr),
        ),
      ],
    ),
    dismissible: false,
  );
  final request = _PairingRequestState(devId: dev.guid, dialogCtl: dlgCtl, notifyId: notifyId);
  self._pairingRequests[dev.guid] = request;
  // 验证码有效期与 verify 的超时判定同源（pairingLimit），到点关闭弹窗、撤销通知并提示过期。
  request.dialogTimeoutTimer = Timer(pairingLimit.s, () {
    if (!self._pairingRequests.containsKey(dev.guid)) {
      return;
    }
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      snackbar.error(currentContext, TranslationKey.devicePagePairingTimeoutText.tr);
    }
    unawaited(self._closePairingRequest(dev.guid));
  });
  await dlgCtl.future;
}

///设备配对
Future<void> _onDevicePairing(SessionNotifier self, MessageData msg, String? address) async {
  final dev = msg.send;
  final code = msg.data['code'];
  //验证配对码
  var verify = self._deviceParingCodeNotifier.verify(dev.guid, code);
  await self.onDevicePaired(dev, verify, address);
  //返回配对结果
  await self.sendData(dev, .paired, {'result': verify}, false);
  self._pendingPairingAddresses.removeWhere((v) {
    return v == address;
  });
  if (verify) {
    // 配对码验证成功，弹窗、通知、超时定时器一并关闭。
    await self._closePairingRequest(dev.guid);
  }
  // 验证失败时什么都不做：
  // - 码错误（有效期内）：配对码、弹窗、通知全保留，发起方重发同一码仍可验证成功；
  // - 码超时：配对码已被 verify 移除，本机弹窗由超时定时器统一关闭并撤销通知。
}

///设备配对完成
Future<void> _onDevicePaired(SessionNotifier self, MessageData msg, String? address) async {
  final dev = msg.send;
  bool result = msg.data['result'];
  await self.onDevicePaired(dev, result, address);
  self._pendingPairingAddresses.removeWhere((v) => v == address);
}

///设备配对取消
void _onDevicePairingCanceled(SessionNotifier self, MessageData msg) {
  final dev = msg.send;
  self._deviceParingCodeNotifier.removeCode(dev.guid);
  unawaited(self.onPairingCanceled(dev));
}
