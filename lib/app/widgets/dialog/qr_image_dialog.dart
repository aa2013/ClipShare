import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrImageDialog extends StatelessWidget {
  final Widget title;
  final String data;
  final double width;

  const QrImageDialog({
    super.key,
    required this.title,
    required this.data,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: IntrinsicHeight(
        child: Center(
          child: SizedBox(
            width: width,
            height: width,
            child: QrImageView(data: data),
          ),
        ),
      ),
    );
  }
}
