import 'package:clipshare/app/utils/extensions/list_extension.dart';
import 'package:clipshare/app/widgets/menu/my_menu_item.dart';
import 'package:flutter/material.dart';

class MyMenu extends StatelessWidget {
  final BorderRadius? borderRadius;
  final AlignmentGeometry? spawnAlignment;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final Clip clipBehavior;
  final BoxDecoration? boxDecoration;
  final List<MyMenuItem> menus;
  final Offset position;

  const MyMenu({
    super.key,
    required this.menus,
    required this.position,
    this.borderRadius,
    this.spawnAlignment,
    this.padding,
    this.maxWidth = 350,
    this.clipBehavior = Clip.antiAlias,
    this.boxDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: _buildMenu(context),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    const separator = SizedBox(height: 8);
    var boxDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withOpacity(0.5),
          offset: const Offset(0.0, 2.0),
          blurRadius: 10,
          spreadRadius: -1,
        )
      ],
      borderRadius: borderRadius ?? BorderRadius.circular(4.0),
    );
    final list = menus.cast<Widget>();
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0.8,
        end: 1.0,
      ),
      duration: const Duration(milliseconds: 60),
      builder: (context, value, child) {
        return Transform.scale(
          alignment: spawnAlignment,
          scale: value,
          child: Container(
            padding: padding,
            constraints: BoxConstraints(maxWidth: maxWidth),
            clipBehavior: clipBehavior,
            decoration: this.boxDecoration ?? boxDecoration,
            child: Material(
              type: MaterialType.transparency,
              child: IntrinsicWidth(
                child: Column(children: list.separateWith(separator, first: true, last: true)),
              ),
            ),
          ),
        );
      },
    );
  }
}
