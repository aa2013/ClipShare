import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';

class DropItemFileUri extends DropItem {
  final String uri;
  final String fileName;
  final int size;

  DropItemFileUri(
    this.uri,
    this.fileName,
    this.size, {
    Uint8List? bytes,
    DateTime? lastModified,
    Uint8List? extraAppleBookmark,
  }) : super(
          uri,
          mimeType: "uri",
          name: fileName,
          length: size,
          bytes: bytes,
          lastModified: lastModified,
          extraAppleBookmark: extraAppleBookmark,
        );

  @override
  Future<int> length() {
    return Future.value(size);
  }

  @override
  String get name => fileName;
}

class MyDropItem {
  final DropItem value;

  MyDropItem(this.value);

  @override
  int get hashCode => value.path.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is MyDropItem && runtimeType == other.runtimeType && value.path == other.value.path;
  }
}
