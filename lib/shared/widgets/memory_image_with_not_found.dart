import 'dart:typed_data';
import 'package:flutter/material.dart';

class MemImageWithNotFound extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final Widget notFoundIcon;
  static const defaultIconSize = 20.0;

  const MemImageWithNotFound({
    super.key,
    required this.bytes,
    required this.width,
    required this.height,
    this.notFoundIcon = const Icon(
      Icons.error_outline,
      color: Colors.orange,
      size: defaultIconSize,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      key: key,
      width: width,
      height: height,
      errorBuilder: (context, Object error, StackTrace? stackTrace) {
        return notFoundIcon;
      },
    );
  }
}
