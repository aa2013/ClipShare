import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/shared/widgets/base/multi_drawer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drawer_provider.g.dart';

class DrawerState {
  final MultiDrawerController controller;
  final double width;

  DrawerState({
    required this.controller,
    this.width = defaultDrawerWidth,
  });
}

@Riverpod(keepAlive: true)
class DrawerNotifier extends _$DrawerNotifier {
  final _controller = MultiDrawerController();

  @override
  DrawerState build() {
    return DrawerState(controller: _controller);
  }

  void resetWidth([double width = defaultDrawerWidth]) {
    state = DrawerState(controller: _controller, width: width);
  }
}
