import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

//返回 true 则正常关闭，否则阻止关闭
typedef BeforeDrawerClosed = FutureOr<bool> Function();

@immutable
class _MultiDrawerChangedValue {
  final bool isPush;
  final Widget? widget;
  final BeforeDrawerClosed? onClosed;

  const _MultiDrawerChangedValue({
    required this.isPush,
    this.widget,
    this.onClosed,
  });
}

class MultiDrawerController extends ValueNotifier<_MultiDrawerChangedValue> {
  final List<Widget> _stack = [];
  static const popValue = _MultiDrawerChangedValue(isPush: false);
  late final _MultiDrawerState _state;

  MultiDrawerController([Widget? root]) : super(_MultiDrawerChangedValue(isPush: true, widget: root)) {
    if (root != null) {
      _stack.add(root);
    }
  }

  List<Widget> get children => List.from(_stack);

  bool get isEmpty => _stack.isEmpty;

  bool get isRoot => _stack.length == 1;

  int get length => _stack.length;

  Widget get current => _stack.last;

  ///[onDrawerClosed] 返回 true 则正常关闭，否则阻止关闭
  void push(Widget widget, BeforeDrawerClosed? onDrawerClosed) {
    _stack.add(widget);
    value = _MultiDrawerChangedValue(isPush: true, widget: widget, onClosed: onDrawerClosed);
  }

  Future<void> popWithAnimation() async {
    await _state.pop();
  }

  Widget pop() {
    if (isEmpty) {
      throw "no elements can be pop";
    }
    final drawer = _stack.removeLast();
    value = _MultiDrawerChangedValue(isPush: false);
    return drawer;
  }

  void closeAll() {
    _stack.clear();
    // 这里不可以用const，否则value视为不变
    value = _MultiDrawerChangedValue(isPush: false);
  }
}

class MultiDrawer extends StatefulWidget {
  final MultiDrawerController controller;
  final double width;
  final double blurSigma;
  final EdgeInsets? padding;
  final Duration? duration;

  const MultiDrawer({
    super.key,
    required this.controller,
    this.width = 400,
    this.blurSigma = 10,
    this.padding,
    this.duration,
  });

  @override
  State<StatefulWidget> createState() => _MultiDrawerState();
}

class _MultiDrawerState extends State<MultiDrawer> with TickerProviderStateMixin {
  MultiDrawerController get controller => widget.controller;
  static const defaultPadding = EdgeInsets.all(8);
  static const defaultDuration = Duration(milliseconds: 200);
  late final AnimationController _overlayController;
  late final Animation<double> _overlayAnimation;
  final List<AnimationController> _slideControllers = [];
  final List<Animation<double>> _slideAnimations = [];
  var _popFuture = Future.value();

  @override
  void initState() {
    controller.addListener(onDrawerChanged);
    controller._state = this;
    _overlayController = AnimationController(
      duration: widget.duration ?? defaultDuration,
      vsync: this,
    );
    _overlayAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _overlayController,
        curve: Curves.easeInOut,
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(onDrawerChanged);
    super.dispose();
  }

  void onDrawerChanged() {
    final value = controller.value;
    if (value.isPush) {
      if (value.widget != null) {
        final slideController = AnimationController(
          duration: widget.duration ?? defaultDuration,
          vsync: this,
        );
        final slideAnimation = Tween<double>(begin: -1 * widget.width, end: 0).animate(
          CurvedAnimation(parent: slideController, curve: Curves.easeInOut),
        );
        _slideControllers.add(slideController);
        _slideAnimations.add(slideAnimation);
        slideController.forward();
        if (controller.isRoot) {
          _overlayController.forward();
        }
      }
    }
    setState(() {});
  }

  Widget buildDrawer(Widget child, [double right = 0]) {
    return Positioned(
      right: right,
      top: 0,
      bottom: 0,
      child: Container(
        width: widget.width,
        padding: widget.padding ?? defaultPadding,
        child: child,
      ),
    );
  }

  Future<void> pop() async {
    _popFuture = _popFuture.then((_) async {
      if (_slideControllers.isEmpty) {
        return;
      }
      final value = controller.value;
      final futureOr = value.onClosed?.call() ?? true;
      var allowClose = false;
      if (futureOr is Future<bool>) {
        allowClose = await futureOr.catchError((_) => false);
      } else {
        allowClose = futureOr;
      }
      if (!allowClose) {
        return;
      }
      var slideController = _slideControllers.last;
      slideController.reverse();
      if (controller.isRoot) {
        _overlayController.reverse();
      }
      return Future.delayed(widget.duration ?? defaultDuration, () {
        if (!controller.isEmpty) {
          controller.pop();
        }
        slideController.forward();
        _slideControllers.removeLast();
        _slideAnimations.removeLast();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isEmpty) {
      return const SizedBox.shrink();
    }
    final drawers = controller.children;
    return Positioned.fill(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              final animation = _overlayAnimation;
              final sigma = animation.value * widget.blurSigma;
              final filter = BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: GestureDetector(
                  onTap: pop,
                  child: Container(
                    color: Colors.black.withOpacity(animation.value * 0.3),
                  ),
                ),
              );
              return ClipRect(child: filter);
            },
          ),
          for (var i = 0; i < drawers.length; i++)
            AnimatedBuilder(
              animation: _slideControllers[i],
              builder: (context, child) {
                final animation = _slideAnimations[i];
                final right = animation.value;
                return buildDrawer(child!, right);
              },
              child: drawers[i],
            ),
        ],
      ),
    );
  }
}
