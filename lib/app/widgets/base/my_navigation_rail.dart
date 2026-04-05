import 'package:flutter/material.dart';

class MyNavigationItem {
  final Widget icon;
  final Widget label;
  final String tooltip;

  const MyNavigationItem({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}

class MyNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final bool extended;
  final double minExtendedWidth;
  final ValueChanged<int> onSelected;
  final List<MyNavigationItem> items;
  final Widget? trailing;

  const MyNavigationRail({
    super.key,
    required this.items,
    required this.extended,
    required this.minExtendedWidth,
    required this.onSelected,
    required this.selectedIndex,
    this.trailing,
  });

  @override
  State<StatefulWidget> createState() => _MyNavigationRailState();
}

class _MyNavigationRailState extends State<MyNavigationRail> {
  static const barWidth = 3.0;
  static const barHeight = 20.0;
  static const itemMarginTop = 2.0;

  double barTopPos = 0;
  double barHeightAnimated = barHeight;

  final List<GlobalKey> keys = [];
  int? hoveredIndex;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.items.length; i++) {
      keys.add(GlobalKey());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateMaskPos(widget.selectedIndex, init: true);
    });
  }

  @override
  void didUpdateWidget(covariant MyNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      updateMaskPos(widget.selectedIndex);
    }
  }

  double calcHeight(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      return box.size.height;
    }
    return 0;
  }

  double calcTop(int index) {
    double top = 0;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      double itemHeight = calcHeight(key);

      if (i < index) {
        top += itemHeight + itemMarginTop * 2;
      }
      if (i == index) {
        top += (itemHeight - barHeight) / 2 + itemMarginTop;
        break;
      }
    }
    return top;
  }

  Future<void> updateMaskPos(int newIndex, {bool init = false}) async {
    double newTop = calcTop(newIndex);

    if (init) {
      setState(() {
        barTopPos = newTop;
        barHeightAnimated = barHeight;
      });
      return;
    }

    double oldTop = barTopPos;
    if (newTop == oldTop) return;

    bool goingDown = newTop > oldTop;

    const duration = Duration(milliseconds: 50);

    if (goingDown) {
      // 向下：先拉伸
      setState(() {
        barHeightAnimated = (newTop - oldTop) + barHeight;
      });

      await Future.delayed(duration);

      // 再移动
      setState(() {
        barTopPos = newTop;
        barHeightAnimated = barHeight;
      });

      await Future.delayed(duration);

      // 收缩
      setState(() {
        barHeightAnimated = barHeight;
      });
    } else {
      // 向上：先拉伸（往上）
      setState(() {
        barTopPos = newTop;
        barHeightAnimated = (oldTop - newTop) + barHeight;
      });

      await Future.delayed(duration);

      // 收缩
      setState(() {
        barHeightAnimated = barHeight;
      });
    }
  }

  Widget buildNavItem(int index) {
    final item = widget.items[index];
    final showBackground = widget.selectedIndex == index || hoveredIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.symmetric(vertical: itemMarginTop),
      decoration: BoxDecoration(
        color: showBackground ? Colors.grey.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        key: keys[index],
        onTap: () {
          widget.onSelected(index);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => hoveredIndex = index),
          onExit: (_) => setState(() => hoveredIndex = null),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10),
            child: Row(
              children: [
                Visibility(
                  visible: widget.extended,
                  replacement: Tooltip(
                    message: item.tooltip,
                    child: item.icon,
                  ),
                  child: item.icon,
                ),
                if (widget.extended) const SizedBox(width: 12),
                if (widget.extended) item.label,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.extended ? widget.minExtendedWidth : 68,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 12),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              top: barTopPos,
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                width: barWidth,
                height: barHeightAnimated,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: const Color(0xff048ae4),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.items.length; i++) buildNavItem(i),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
