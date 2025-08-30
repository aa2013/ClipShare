import 'dart:async';

import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/cupertino.dart';

class LoadingDots extends StatefulWidget {
  final Widget text;

  const LoadingDots({super.key, required this.text});

  @override
  State<StatefulWidget> createState() {
    return _LoadingDotsState();
  }
}

class _LoadingDotsState extends State<LoadingDots> {
  late Timer _timer;
  int _dots = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(500.ms, (Timer timer) {
      setState(() {
        _dots = (_dots % 3) + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.text,
        SizedBox(
          width: 15,
          child: Text("." * _dots),
        )
      ],
    );
  }
}
