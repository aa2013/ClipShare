import 'package:clipshare/app/utils/log.dart';

enum MsgType {
  //设备连接
  connect,
  //同步确认
  ackSync,
  //在线数据同步
  sync,
  //广播信息
  broadcastInfo,
  //请求配对（生成配对码）
  reqPairing,
  //请求配对（验证配对码）
  pairing,
  //取消配对
  cancelPairing,
  //设备配对成功
  paired,
  //设置置顶（或非置顶）
  setTop,
  //请求缺失数据
  reqMissingData,
  //同步缺失数据
  missingData,
  //删除记录
  rmHistory,
  //配对情况
  pairedStatus,
  //手动断开连接
  disConnect,
  //忘记设备
  forgetDev,
  ping,
  pingResult,
  //文件同步
  file,
  //未知key
  unknown;

  static MsgType getValue(String name) => MsgType.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("MsgKey", "key '$name' unknown");
          return MsgType.unknown;
        },
      );
}
