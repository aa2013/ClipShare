import 'package:clipshare/shared/widgets/layouts/my_navigation_rail.dart';
import 'package:flutter/material.dart';

class HomeWidePage extends StatefulWidget {
  final List<Widget> pages;
  final double minExtendedWidth;
  final List<MyNavigationItem> navItems;

  const HomeWidePage({
    super.key,
    required this.navItems,
    required this.pages,
    this.minExtendedWidth = 200,
  });

  @override
  State<StatefulWidget> createState() => _HomeWidePageSate();
}

class _HomeWidePageSate extends State<HomeWidePage> {
  var extended = true;
  var index = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildNavigationRail(context),
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                TickerMode(
                  enabled: i == index,
                  child: widget.pages[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return MyNavigationRail(
      extended: extended,
      onSelected: (i) => setState(() {
        index = i;
      }),
      minExtendedWidth: widget.minExtendedWidth,
      items: widget.navItems,
      selectedIndex: index,
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IconButton(
              icon: Icon(
                extended ? Icons.keyboard_double_arrow_left_outlined : Icons.keyboard_double_arrow_right_outlined,
                color: Colors.blueGrey,
              ),
              onPressed: () {
                setState(() {
                  extended = !extended;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
