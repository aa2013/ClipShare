import 'package:flutter/cupertino.dart';

class DrawerModel {
  final Widget drawer;
  final Function? onDrawerClosed;
  final double width;

  DrawerModel({required this.drawer, this.onDrawerClosed, required this.width});
}
