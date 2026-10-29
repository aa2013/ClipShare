import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MyMenuItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  final void Function() onSelected;

  const MyMenuItem({
    super.key,
    required this.label,
    this.icon,
    required this.onSelected,
  });

  @override
  State<StatefulWidget> createState() => _MyMenuItemState();
}

class _MyMenuItemState extends State<MyMenuItem> {
  bool isFocused = false;

  void _onMouseEnter(PointerEnterEvent event) {
    setState(() {
      isFocused = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      isFocused = false;
    });
  }

  void _onHover(PointerHoverEvent event) {
    setState(() {
      isFocused = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = colorScheme.surface;
    final normalTextColor = Color.alphaBlend(
      colorScheme.onSurface.withOpacity(0.7),
      background,
    );
    final focusedTextColor = colorScheme.onSurface;
    final foregroundColor = isFocused ? focusedTextColor : normalTextColor;
    final textStyle = TextStyle(color: foregroundColor, height: 1.0);
    return MouseRegion(
      onEnter: (event) => _onMouseEnter(event),
      onExit: (event) => _onExit(event),
      onHover: (event) => _onHover(event),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8.0),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onTap: widget.onSelected,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: isFocused ? Colors.grey.withOpacity(0.2) : null,
              ),
              child: DefaultTextStyle(
                style: textStyle,
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 32.0,
                      child: Icon(
                        widget.icon,
                        size: 16.0,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    SizedBox.square(
                      dimension: 32.0,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(
                          null,
                          size: 16.0,
                          color: foregroundColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
