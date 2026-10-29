//socket包头部大小
const int packetHeaderSize = 10;

//socket包载荷最大大小
const int packetMaxPayloadSize = (1 << 2 * 8) - 1;

// Socket TCP 建连超时时间，超时后必须取消底层 ConnectionTask。
const Duration socketConnectTimeout = Duration(seconds: 2);

// Socket 加密握手与设备状态交换沿用同一个等待窗口。
const Duration socketHandshakeTimeout = Duration(seconds: 5);

// Socket 关闭先尝试有界优雅关闭，随后始终 destroy。
const Duration socketGracefulCloseTimeout = Duration(seconds: 1);

// 设备断线后的重试间隔与最长持续时间。
const Duration socketReconnectInterval = Duration(seconds: 2);
const Duration socketReconnectWindow = Duration(minutes: 3);

// 中转控制连接只保留一个延迟重试定时器。
const Duration forwardReconnectDelay = Duration(seconds: 1);

// 在线强制探测必须在该窗口内收到明确 pingResult。
const Duration socketOnlineProbeTimeout = Duration(seconds: 2);

// 可取消建连使用短轮询桥接 Dart Socket.startConnect 的 cancel 语义。
const Duration socketCancelPollInterval = Duration(milliseconds: 50);

//组播默认端口
const int port = 42317;

//组播地址
const String multicastGroup = '224.0.0.128';

//组播心跳时长
const heartbeatInterval = 30;
//websocket心跳时长
const defaultWsPingIntervalTime = 30;
