import 'device_connect_exception.dart';

/// Socket 在 ready 之前的握手协议或对端身份校验失败。
class SocketHandshakeException extends DeviceConnectException {
  const SocketHandshakeException(super.message);

  @override
  String toString() => 'SocketHandshakeException: $message';
}
