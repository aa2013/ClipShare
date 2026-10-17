part of 'session_provider.dart';

const sessionTag = 'SessionNotifier';

/// 读取同步消息的原始操作 id，只有能定位发送端 OperationRecord 时才允许公共层回 ACK。
int? _syncAckOpId(MessageData msg) {
  final id = msg.data['id'];
  if (id is int) {
    return id;
  }
  if (id is String) {
    return int.tryParse(id);
  }
  return null;
}

///数据同步处理
void _onSyncMsg(SessionNotifier self, MessageData msg) {
  Module module = Module.getValue(msg.data['module']);
  logger.debug(sessionTag, 'module ${module.moduleName}');
  final opId = _syncAckOpId(msg);
  final isReceivedSync = msg.key == MsgType.sync || msg.key == MsgType.missingData;
  final shouldAckReceivedSync = isReceivedSync && opId != null && module != Module.unknown;
  if (isReceivedSync && !shouldAckReceivedSync) {
    logger.warn(
      sessionTag,
      'skip sync ack because message is not recognizable. '
      'key=${msg.key.name}, data=${jsonEncode(msg.data)}',
    );
  }
  //todo 筛选某个模块的同步处理器
  // var lst = getListeners(module);
  // if (isReceivedSync) {
  //   dbService.execSequentially(() async {
  //     for (var listener in lst) {
  //       try {
  //         await listener.onSync(msg);
  //       } catch (err, stack) {
  //         logger.error(tag, err, stack);
  //       }
  //     }
  //     if (shouldAckReceivedSync) {
  //       await AckSyncSender.send(
  //         msg.send,
  //         opId,
  //         {
  //           'id': opId,
  //           'module': module.moduleName,
  //         },
  //       );
  //     }
  //   });
  //   return;
  // }
  // for (var listener in lst) {
  //   switch (msg.key) {
  //     case MsgType.ackSync:
  //       dbService.execSequentially(() => listener.ackSync(msg));
  //       break;
  //     default:
  //       break;
  //   }
  // }
}

///缺失数据同步
void _onMissingData(SessionNotifier self, MessageData msg) {
  var copyMsg = MessageData.fromJson(msg.toJson());
  var data = msg.data['data'] as Map<dynamic, dynamic>;
  copyMsg.data = data.cast<String, dynamic>();
  final total = msg.data['total'];
  int seq = msg.data['seq'];
  //todo
  // final syncProgressService = Get.find<HistorySyncProgressService>();
  // syncProgressService.addProgress(copyMsg.send.guid, copyMsg.data, seq, total, false);
  _onSyncMsg(self, copyMsg);
}

///请求缺失数据
void _onRequestMissingData(SessionNotifier self, MessageData msg) {
  var syncedAppIds = ((msg.data['appIds'] ?? []) as List<dynamic>).cast<String>();
  //todo
  // MissingDataSyncHandler.sendMissingData(dev, _self.guid, syncedAppIds);
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
  final ruesExecutor = ref.read(rulesExecutorProvider.notifier);

  final notExists = ruesExecutor.isNotExistAppInfo(sourceAppInfo.appId);
  final appInfo = sourceAppInfo.id == 0 ? sourceAppInfo.copyWith(id: sourceAppInfo.appId.hash64) : sourceAppInfo;
  final success = await clipboardSourceNotifier.addOrUpdate(appInfo);
  // todo
  // if (success && notExists) {
  //   ruleController.update();
  // }
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
