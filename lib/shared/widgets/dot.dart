import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final double radius;
  final Color color;

  const Dot({
    super.key,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
