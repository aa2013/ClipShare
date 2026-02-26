import 'package:flutter/material.dart';

class TinySegmentedControl extends StatefulWidget {
  final List<Widget> options;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BorderRadius? contentBorderRadius;
  final Color? selectedBackgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final FontWeight? fontWeight;
  final Duration? duration;
  final bool enableSplash;
  final int initialSelected;
  final double segmentSpacing;
  final ValueChanged<int> onSelected;
  final int? selectedIndex;
  static const _defaultEnableSplash = true;
  static const _defaultInitialSelected = 0;
  static const _defaultSegmentSpacing = 4.0;

  const TinySegmentedControl({
    super.key,
    required this.options,
    required this.onSelected,
    this.padding,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
    this.contentBorderRadius,
    this.selectedBackgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.fontWeight,
    this.duration,
    this.enableSplash = _defaultEnableSplash,
    this.initialSelected = _defaultInitialSelected,
    this.segmentSpacing = _defaultSegmentSpacing,
    this.selectedIndex,
  }) : assert(segmentSpacing >= 0),
        assert(initialSelected >= 0),
        assert(options.length > 0);

  factory TinySegmentedControl.fromStrings({
    Key? key,
    required List<String> options,
    required ValueChanged<int> onSelected,
    TextStyle? textStyle,
    EdgeInsets? padding,
    EdgeInsets? contentPadding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BorderRadius? contentBorderRadius,
    Color? selectedBackgroundColor,
    Color? selectedColor,
    Color? unselectedColor,
    FontWeight? fontWeight,
    Duration? duration,
    bool enableSplash = _defaultEnableSplash,
    int initialSelected = _defaultInitialSelected,
    double segmentSpacing = _defaultSegmentSpacing,
    int? selectedIndex,
  }) {
    return TinySegmentedControl(
      key: key,
      options: options.map((e) => Text(e, style: textStyle)).toList(),
      onSelected: onSelected,
      padding: padding,
      contentPadding: contentPadding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      contentBorderRadius: contentBorderRadius,
      selectedBackgroundColor: selectedBackgroundColor,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
      fontWeight: fontWeight,
      duration: duration,
      enableSplash: enableSplash,
      initialSelected: initialSelected,
      segmentSpacing: segmentSpacing,
      selectedIndex: selectedIndex,
    );
  }

  @override
  State<StatefulWidget> createState() => _TinySegmentedControlState();
}

class _TinySegmentedControlState extends State<TinySegmentedControl> {
  static const _defaultPadding = EdgeInsets.all(4);
  static const _defaultContentPadding = EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 2,
  );
  static final _defaultBorderRadius = BorderRadius.circular(8);
  static final _defaultContentBorderRadius = BorderRadius.circular(6);
  static const _defaultDuration = Duration(milliseconds: 300);

  static const _defaultLightBackgroundColor = Color(0xFFE0E0E0); //Colors.grey[200]
  static const _defaultLightSelectedBackgroundColor = Colors.white;
  static const _defaultLightSelectedColor = Colors.black;
  static const _defaultLightUnselectedColor = Colors.black;

  static const _defaultDarkBackgroundColor = Color(0xFF303030); //Colors.grey[800]
  static const _defaultDarkSelectedBackgroundColor = Color(0xFF212121); //Colors.grey[900]
  static const _defaultDarkSelectedColor = Colors.white;
  static const _defaultDarkUnselectedColor = Color(0xFFB0B0B0); //Colors.grey[400]

  int _selectedIndex = 0;

  final List<GlobalKey> _keys = [];
  List<Widget> _options = [];
  double maskWidth = 0;
  double maskLeftOffset = 0;

  @override
  void initState() {
    super.initState();
    _options.addAll(widget.options);
    _selectedIndex = widget.initialSelected;
    _keys.addAll(List.generate(_options.length, (_) => GlobalKey()));
  }

  @override
  void didUpdateWidget(covariant TinySegmentedControl oldWidget) {
    final diff = widget.options.length - _options.length;
    _options = [...widget.options];
    if(widget.selectedIndex != null){
      assert(widget.selectedIndex! < _options.length && widget.selectedIndex! >= 0);
      _selectedIndex = widget.selectedIndex!;
    }
    if (diff == 0) {
      return;
    }
    if (diff > 0) {
      for (var i = 0; i < diff; i++) {
        _keys.add(GlobalKey());
      }
    } else {
      _keys.removeRange(widget.options.length, _keys.length);
    }
    super.didUpdateWidget(oldWidget);
  }

  double calcWidth(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      return box.size.width;
    }
    return 0;
  }

  void updateMaskPos() {
    double width = 0;
    double leftOffset = 0;
    for (var i = 0; i < _keys.length; i++) {
      final key = _keys[i];
      double itemWidth = calcWidth(key);
      if (i < _selectedIndex) {
        leftOffset += itemWidth + widget.segmentSpacing;
      }
      if (i == _selectedIndex) {
        width = itemWidth;
        break;
      }
    }
    if (width == maskWidth && leftOffset == maskLeftOffset) {
      return;
    }
    setState(() {
      maskWidth = width;
      maskLeftOffset = leftOffset;
    });
  }

  Color _getDefaultColor({
    Color? customColor,
    required Color lightColor,
    required Color darkColor,
  }) {
    if (customColor != null) return customColor;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightColor : darkColor;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => updateMaskPos());

    //region DefaultColors
    final defaultBackgroundColor = _getDefaultColor(
      customColor: widget.backgroundColor,
      lightColor: _defaultLightBackgroundColor,
      darkColor: _defaultDarkBackgroundColor,
    );

    final defaultSelectedBackgroundColor = _getDefaultColor(
      customColor: widget.selectedBackgroundColor,
      lightColor: _defaultLightSelectedBackgroundColor,
      darkColor: _defaultDarkSelectedBackgroundColor,
    );

    final defaultSelectedColor = _getDefaultColor(
      customColor: widget.selectedColor,
      lightColor: _defaultLightSelectedColor,
      darkColor: _defaultDarkSelectedColor,
    );

    final defaultUnselectedColor = _getDefaultColor(
      customColor: widget.unselectedColor,
      lightColor: _defaultLightUnselectedColor,
      darkColor: _defaultDarkUnselectedColor,
    );
    //endregion

    return Container(
      padding: widget.padding ?? _defaultPadding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? defaultBackgroundColor,
        borderRadius: widget.borderRadius ?? _defaultBorderRadius,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: widget.duration ?? _defaultDuration,
            curve: Curves.easeInOut,
            left: maskLeftOffset,
            top: 0,
            bottom: 0,
            width: maskWidth,
            child: Container(
              decoration: BoxDecoration(
                color: widget.selectedBackgroundColor ?? defaultSelectedBackgroundColor,
                borderRadius: widget.contentBorderRadius ?? _defaultContentBorderRadius,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: widget.segmentSpacing,
            children: List.generate(_options.length, (index) {
              final color = _selectedIndex == index
                  ? widget.selectedColor ?? defaultSelectedColor
                  : widget.unselectedColor ?? defaultUnselectedColor;
              final child = InkWell(
                borderRadius: widget.contentBorderRadius ?? _defaultContentBorderRadius,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onSelected(index);
                },
                child: Container(
                  key: _keys[index],
                  padding: widget.contentPadding ?? _defaultContentPadding,
                  child: AnimatedDefaultTextStyle(
                    style: TextStyle(
                      color: color,
                      fontWeight: widget.fontWeight,
                    ),
                    duration: widget.duration ?? _defaultDuration,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: widget.duration ?? _defaultDuration,
                      curve: Curves.easeInOut,
                      builder: (context, animatedColor, child) {
                        return IconTheme(
                          data: IconThemeData(color: animatedColor),
                          child: _options[index],
                        );
                      },
                    ),
                  ),
                ),
              );
              if (widget.enableSplash) {
                return Material(color: Colors.transparent, child: child);
              } else {
                return child;
              }
            }),
          ),
        ],
      ),
    );
  }
}
