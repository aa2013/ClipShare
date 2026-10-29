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
