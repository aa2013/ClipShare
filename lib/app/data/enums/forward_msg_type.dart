import 'package:clipshare/app/utils/log.dart';

enum ForwardMsgType {
  //中转模式已准备好
  forwardReady,
  //中转双方已连接
  bothConnected,
  //请求连接设备
  requestConnect,
  //文件接收者已连接
  fileReceiverConnected,
  //有设备向自己发送文件
  sendFile,
  //取消发送文件
  cancelSendFile,
  //检查中转是否有效
  check,
  //不允许文件同步
  fileSyncNotAllowed,
  //ping
  ping,
  version,
  //未知key
  unknown;

  static ForwardMsgType getValue(String name) =>
      ForwardMsgType.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("ForwardMsgType", "key '$name' unknown");
          return ForwardMsgType.unknown;
        },
      );
}

enum ForwardConnType {
  //基础连接
  base,
  //准备文件发送
  sendFile,
  //准备文件接收
  recFile,
  //检查中转是否有效
  check,
}
