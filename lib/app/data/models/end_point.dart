import 'package:clipshare/app/data/models/dev_info.dart';

class EndPoint {
  final String host;
  final int port;

  const EndPoint(this.host, this.port);

  @override
  String toString() {
    return "host: $host, port: $port";
  }
}

class DeviceEndPoint extends EndPoint {
  final DevInfo devInfo;

  DeviceEndPoint(this.devInfo, super.host, super.port);

  @override
  String toString() {
    final superStr = super.toString();
    return "devId = ${devInfo.guid}, devName = ${devInfo.name}, devType = ${devInfo.type}, $superStr";
  }
}


