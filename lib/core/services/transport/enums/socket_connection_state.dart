/// Socket 连接生命周期状态，供底层客户端统一约束资源收口。
enum SocketConnectionState {
  connecting,
  handshaking,
  ready,
  closing,
  closed,
}
