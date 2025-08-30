import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingCard<T> extends StatefulWidget {
  final T value;
  final Widget title;
  final Widget? description;
  final Widget Function(T val)? action;
  bool separate;
  final bool showValueInSub;
  late BorderRadius borderRadius;
  final bool Function(T)? show;
  void Function()? onTap;
  void Function()? onDoubleTap;
  late final EdgeInsetsGeometry padding;

  SettingCard({
    super.key,
    required this.title,
    required this.value,
    this.description,
    this.action,
    this.separate = false,
    this.showValueInSub = false,
    this.onTap,
    this.onDoubleTap,
    this.borderRadius = BorderRadius.zero,
    this.show,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingCardState<T>();
  }
}

class _SettingCardState<T> extends State<SettingCard<T>> {
  bool _readyDoubleClick = false;

  @override
  Widget build(BuildContext context) {
    //不显示内容
    if (widget.show != null && !widget.show!.call(widget.value)) {
      return const SizedBox.shrink();
    }
    Widget? sub = widget.description;
    if (widget.showValueInSub) {
      sub = Text(widget.value.toString());
    }
    final currentTheme = Theme.of(context);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Material(
        color: currentTheme.cardTheme.color ?? currentTheme.colorScheme.surface,
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
                //设置了双击，但仅点击了一次，延迟一段时间
                Future.delayed(300.ms, () {
                  if (_readyDoubleClick) {
                    //指定时间后仍然没有进行第二次点击，进行单击逻辑
                    widget.onTap?.call();
                  }
                  //指定时间后无论是否双击，恢复状态
                  _readyDoubleClick = false;
                });
              }
            }
          },
          mouseCursor: SystemMouseCursors.basic,
          child: Column(
            children: [
              Padding(
                padding: widget.padding,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: sub == null ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Expanded(
                              // flex: widget.titleFlex,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Center(
                                  child: DefaultTextStyle(
                                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 17,
                                    ),
                                    child: widget.title,
                                  ),
                                ),
                              ),
                            ),
                            if (sub != null)
                              Wrap(
                                children: [
                                  DefaultTextStyle(
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Colors.grey,
                                    ),
                                    child: sub,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      IntrinsicWidth(
                        child: widget.action == null ? const SizedBox.shrink() : widget.action!.call(widget.value),
                      ),
                    ],
                  ),
                ),
              ),
              widget.separate
                  ? Divider(
                      thickness: 1,
                      height: 1,
                      color: Get.isDarkMode ? null : const Color.fromRGBO(232, 228, 228, 1.0),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
