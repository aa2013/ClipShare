import 'package:clipshare/app/data/enums/forward_server_status.dart';

/// 统一接收中转链路状态变化，避免不同传输实现扩散多套回调。
abstract class ForwardStatusListener {
  void onForwardServerStatusChanged(ForwardServerStatus status);
}
