part of 'forward_server_provider.dart';

///收到中转心跳
void _onForwardPing(ForwardServerNotifier self) {
  self._lastForwardServerPingTime = DateTime.now();
}

///不允许文件同步
Future<void> _onForwardFileSyncNotAllowed(BuildContext context) async {
  await dialogManager.tips(
    context,
    text: TranslationKey.forwardServerNotAllowedSendFile.tr,
    title: TranslationKey.sendFailed.tr,
  );
}

///中转检测
Future<void> _onForwardCheck(ForwardServerNotifier self, BuildContext context, Map<String, dynamic> data) async {
  Future<void> disableForwardServerAfterDelay() async {
    await Future.delayed(500.ms);
    if (self._forwardClient != null) {
      return;
    }
    await self._configDao.addOrUpdate(.enableForward, false.toString());
    self._invalidate(discoverySettingsProvider);
  }

  if (!data.containsKey('result')) {
    await dialogManager.tips(
      context,
      text: '${TranslationKey.forwardServerUnknownResult.tr}:\n ${data.toString()}',
      title: TranslationKey.forwardServerConnectFailed.tr,
    );
    unawaited(disableForwardServerAfterDelay());
    return;
  }
  final result = data['result'];
  if (result == 'success') {
    return;
  }
  unawaited(disableForwardServerAfterDelay());
  await dialogManager.tips(
    context,
    text: result,
    title: TranslationKey.forwardServerConnectFailed.tr,
  );
}

///中转连接请求
void _onForwardRequestConnect(ForwardServerNotifier self, Map<String, dynamic> data) {
  final targetId = data['sender'];
  unawaited(self.manualConnectByForward(targetId));
}

///收到中转服务版本信息
void _onForwardVersion(ForwardServerNotifier self, Map<String, dynamic> data) {
  final version = data['version']?.toString();
  self._appStateNotifier.updateTransportServerVersion(version ?? '');
}

///中转文件发送请求
Future<void> _onForwardRequestSendFile(ForwardServerNotifier self, BuildContext context, Map<String, dynamic> data) async {
  final targetId = data['sender'];
  final size = data['size'].toString().toInt();
  final fileName = data['fileName'];
  final fileId = data['fileId'].toString().toInt();
  final userId = data['userId'].toString().toInt();
  //连接中转接收文件
  try {
    //todo
    // await FileSyncHandler.receiveFile(
    //   isForward: true,
    //   ip: self.forwardServerHost!,
    //   port: self.forwardServerPort!,
    //   size: size,
    //   fileName: fileName,
    //   devId: targetId,
    //   userId: userId,
    //   fileId: fileId,
    //   context: context,
    //   targetId: targetId,
    // );
  } catch (err, stack) {
    logger.debug(
      ForwardServerNotifier.tag,
      'receive file failed from forward'
      '$err $stack',
    );
  }
}

/// 中转文件发送记录，server 通知接收端 ready 时按 fileId 找回 handler。
// todo
// final Map<int, FileSyncHandler> _forwardFiles = {};
///中转文件接收者已连接
void _onForwardFileReceiverConnected(ForwardServerNotifier self, Map<String, dynamic> data) {
  //接收方已连接，开始发送
  final fileId = data['fileId'].toString().toInt();
  //todo
  // if (self._forwardFiles.containsKey(fileId)) {
  //   self._forwardFiles[fileId]!.onForwardReceiverConnected();
  // } else {
  //   logger.warn(tag, 'fileReceiverConnected but not fileId in waiting list');
  // }
}

///添加中转文件发送记录
// todo
// void addSendFileRecordByForward(FileSyncHandler fileSyncer, int fileId) {
//   if (_forwardFiles.containsKey(fileId)) {
//     throw Exception('The file is already in the sending list: $fileId');
//   }
//   _forwardFiles[fileId] = fileSyncer;
// }

///移除中转文件发送记录
//todo
// void removeSendFileRecordByForward(
//   FileSyncHandler fileSyncer,
//   int fileId,
//   String? targetDevId,
// ) {
//   _forwardFiles.remove(fileId);
//   if (targetDevId != null) {
//     _forwardClient?.send({
//       'type': ForwardMsgType.cancelSendFile.name,
//       'targetId': targetDevId,
//     });
//   }
// }
