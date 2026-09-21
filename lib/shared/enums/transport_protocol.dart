enum TransportProtocol {
  direct,
  server,
  webdav,
  s3;

  //todo
  // DataSender? get dataSender {
  //   if (this == direct || this == server) {
  //     return Get.find<SocketService>();
  //   }
  //   if (this == webdav) {
  //     return Get.find<StorageService>();
  //   }
  //   return null;
  // }
  //
  // static List<DataSender> get dataSenders {
  //   return TransportProtocol.values.where((p) => p != server).map((p) => p.dataSender).where((sender) => sender != null).toList(growable: false).cast();
  // }

  bool get isSocket => this == direct || this == server;

  bool get isStorage => this == webdav || this == s3;
}
