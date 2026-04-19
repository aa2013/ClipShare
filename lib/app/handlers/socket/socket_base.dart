import 'package:clipshare/app/listeners/socket_client_msg_observer.dart';

abstract class SocketClientBase<T> {
  Future<void> send(Map<String,dynamic> map);

  Future<void> close();

  void register(SocketClientMsgObserver<T> observer);

  void unregister(SocketClientMsgObserver<T> observer);
}
