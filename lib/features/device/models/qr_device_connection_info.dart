import 'dart:convert';

class QRDeviceConnectionInfo {
  final String id;

  final List<DeviceInterfaceInfo> interfaces;

  QRDeviceConnectionInfo({
    required this.id,
    required this.interfaces,
  });

  factory QRDeviceConnectionInfo.fromJson(Map<String, dynamic> json) {
    var id = json['id'];
    List<dynamic> list = json['interfaces'];
    return QRDeviceConnectionInfo(
      id: id,
      interfaces: list.map((item) {
        return DeviceInterfaceInfo.fromJson(item);
      }).toList(),
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interfaces': interfaces,
    };
  }
}

class DeviceInterfaceInfo {
  final String name;
  final List<String> addresses;

  const DeviceInterfaceInfo({
    required this.name,
    required this.addresses,
  });

  factory DeviceInterfaceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInterfaceInfo(
      name: json['name'],
      addresses: (json['addresses'] as List<dynamic>).cast<String>(),
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'addresses': addresses,
    };
  }
}
