import 'dart:math';

import 'package:flutter/material.dart';

class LadingProgressController extends ValueNotifier<int> {
  int total;

  LadingProgressController({
    this.total = 0,
  }) : super(0);

  void update(int progress, [int? total]) {
    print("onUpdate $progress");
    if (total != null) {
      this.total = total;
    }
    value = progress.clamp(0, max(0, this.total));
  }
}

class Loading extends StatefulWidget {
  final double width;
  final Widget? description;
  final LadingProgressController? controller;

  const Loading({
    super.key,
    this.width = 24,
    this.description,
    this.controller,
  });

  @override
  State<StatefulWidget> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(onProgressUpdate);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(onProgressUpdate);
    super.dispose();
  }

  void onProgressUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final description = widget.description;
    var showProgress = widget.controller != null;
    var current = 0;
    var total = 0;
    if (showProgress) {
      current = widget.controller!.value;
      total = widget.controller!.total;
    }
    showProgress = showProgress && total != 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            height: width,
            child: const CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          ),
          if (description != null || showProgress)
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (description != null) description,
                  if (showProgress) Text("($current/$total)"),
                ],
              ),
            )
        ],
      ),
    );
  }
}
