import 'package:flutter/widgets.dart';

class ConditionWidget extends StatelessWidget {
  final Widget child;
  final Widget? replacement;
  final bool visible;

  const ConditionWidget({
    super.key,
    required this.visible,
    required this.child,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    return visible ? child : replacement ?? const SizedBox.shrink();
  }
}
