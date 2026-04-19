import 'package:clipshare/app/handlers/socket/socket_base.dart';

abstract mixin class SocketClientMsgObserver<T> {
  Future<void> onMessageReceived(SocketClientBase client, T data);
}

