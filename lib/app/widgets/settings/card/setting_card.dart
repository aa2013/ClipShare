import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/settings_module/settings_text_styles.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract interface class SettingEntry {
  bool get visible;
  String get searchId;
  List<TranslationKey> get searchKeys;
  List<String> get searchAliases;

  Widget buildWithLayout({
    required BorderRadius borderRadius,
    required bool separate,
  });
}

class SettingCard<T> extends StatefulWidget implements SettingEntry {
  final T value;
  final Widget title;
  final Widget? description;
  final Widget Function(T val)? action;
  final bool separate;
  final bool showValueInSub;
  final BorderRadius borderRadius;
  final bool Function(T)? show;
  final void Function()? onTap;
  final void Function(TapDownDetails details)? onTapDown;
  final void Function()? onDoubleTap;
  final EdgeInsetsGeometry padding;
  @override
  final List<TranslationKey> searchKeys;
  @override
  final List<String> searchAliases;
  final String? explicitSearchId;

  const SettingCard({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.action,
    this.separate = false,
    this.showValueInSub = false,
    this.onTap,
    this.onTapDown,
    this.onDoubleTap,
    this.borderRadius = BorderRadius.zero,
    this.show,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.searchKeys = const [],
    this.searchAliases = const [],
    String? searchId,
  }) : explicitSearchId = searchId;

  @override
  bool get visible => show?.call(value) != false;

  @override
  String get searchId {
    if (explicitSearchId != null && explicitSearchId!.isNotEmpty) {
      return explicitSearchId!;
    }
    final parts = [
      ...searchKeys.map((key) => key.name),
      ...searchAliases,
    ];
    return parts.join('|');
  }

  @override
  Widget buildWithLayout({
    required BorderRadius borderRadius,
    required bool separate,
  }) {
    return SettingCard<T>(
      key: key,
      title: title,
      value: value,
      description: description,
      action: action,
      separate: separate,
      showValueInSub: showValueInSub,
      onTap: onTap,
      onTapDown: onTapDown,
      onDoubleTap: onDoubleTap,
      borderRadius: borderRadius,
      show: show,
      padding: padding,
      searchKeys: searchKeys,
      searchAliases: searchAliases,
      searchId: explicitSearchId,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _SettingCardState<T>();
  }
}

class _SettingCardState<T> extends State<SettingCard<T>> with SingleTickerProviderStateMixin {
  bool _readyDoubleClick = false;
  bool _doubleClickWait = false;
  String? _lastHighlightedSearchId;
  late final AnimationController _highlightController;
  late final Animation<double> _highlightOpacity;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _highlightOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 42),
    ]).animate(CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //不显示内容
    if (!widget.visible) {
      return const SizedBox.shrink();
    }
    Widget? sub = widget.description;
    if (widget.showValueInSub) {
      sub = Text(widget.value.toString());
    }
    final currentTheme = Theme.of(context);
    final dividerColor = currentTheme.colorScheme.onSurface
        .withValues(alpha: Get.isDarkMode ? 0.12 : 0.08);
    final highlightedSearchId = SettingSearchHighlightScope.maybeOf(context)?.searchId;
    final shouldHighlight = highlightedSearchId != null && highlightedSearchId.isNotEmpty && widget.searchId == highlightedSearchId;
    _startHighlightIfNeeded(shouldHighlight, highlightedSearchId);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AnimatedBuilder(
        animation: _highlightOpacity,
        builder: (context, child) {
          final baseColor = currentTheme.cardTheme.color ?? currentTheme.colorScheme.surface;
          final highlightColor = currentTheme.colorScheme.primary.withValues(
            alpha: (Get.isDarkMode ? 0.22 : 0.14) * _highlightOpacity.value,
          );
          return Material(
            color: Color.alphaBlend(highlightColor, baseColor),
            child: child,
          );
        },
        child: InkWell(
          onTap: () {
            if (widget.onDoubleTap == null) {
              //未设置双击，直接执行单击
              widget.onTap?.call();
            } else {
              //设置了双击，且已经点击过一次，执行双击逻辑
              if (_readyDoubleClick) {
                widget.onDoubleTap!.call();
                //双击结束，恢复状态
                _readyDoubleClick = false;
              } else {
                _readyDoubleClick = true;
                _doubleClickWait = true;
                //设置了双击，但仅点击了一次，延迟一段时间
                Future.delayed(300.ms, () {
                  if (_readyDoubleClick) {
                    //指定时间后仍然没有进行第二次点击，进行单击逻辑
                    widget.onTap?.call();
                  }
                  //指定时间后无论是否双击，恢复状态
                  _readyDoubleClick = false;
                  _doubleClickWait = false;
                });
              }
            }
          },
          onTapDown: (details) {
            if (_doubleClickWait) {
              return;
            }
            if (widget.onDoubleTap == null) {
              //未设置双击，直接执行
              widget.onTapDown?.call(details);
            } else {
              Future.delayed(305.ms, () {
                if (_doubleClickWait || _readyDoubleClick) return;
                //指定时间后仍然没有进行第二次点击，进行单击逻辑
                widget.onTapDown?.call(details);
              });
            }
          },
          mouseCursor: SystemMouseCursors.basic,
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: widget.padding,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: sub == null
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              // 标题不占用剩余高度，避免英文说明文字在右侧有 action 时被压到裁切。
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Center(
                                  child: DefaultTextStyle(
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                    child: widget.title,
                                  ),
                                ),
                              ),
                              if (sub != null)
                                Wrap(
                                  children: [
                                    DefaultTextStyle(
                                      style: SettingsTextStyles.settingDescription(context),
                                      child: sub,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        IntrinsicWidth(
                          child: widget.action == null
                              ? const SizedBox.shrink()
                              : widget.action!.call(widget.value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              widget.separate
                  ? Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Divider(
                        thickness: 1,
                        height: 1,
                        color: dividerColor,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  void _startHighlightIfNeeded(bool shouldHighlight, String? highlightedSearchId) {
    if (!shouldHighlight || highlightedSearchId == _lastHighlightedSearchId) {
      return;
    }
    _lastHighlightedSearchId = highlightedSearchId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.24,
      );
      _highlightController.forward(from: 0);
    });
  }
}

class SettingSearchHighlightScope extends InheritedWidget {
  final String? searchId;

  const SettingSearchHighlightScope({
    super.key,
    required this.searchId,
    required super.child,
  });

  static SettingSearchHighlightScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingSearchHighlightScope>();
  }

  @override
  bool updateShouldNotify(SettingSearchHighlightScope oldWidget) {
    return searchId != oldWidget.searchId;
  }
}
