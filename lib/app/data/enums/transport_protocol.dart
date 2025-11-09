import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:get/get.dart';

enum TransportProtocol {
  direct,
  server,
  webdav,
  s3;

  DataSender? get dataSender {
    if (this == direct || this == server) {
      return Get.find<SocketService>();
    }
    if (this == webdav) {
      return Get.find<StorageService>();
    }
    return null;
  }

  static List<DataSender> get dataSenders {
    return TransportProtocol.values.where((p) => p != server).map((p) => p.dataSender).where((sender) => sender != null).toList(growable: false).cast();
  }

  bool get isSocket => this == direct || this == server;
}
