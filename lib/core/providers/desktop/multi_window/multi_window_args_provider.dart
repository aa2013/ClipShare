import 'package:clipshare/shared/models/desktop_multi_window_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multi_window_args_provider.g.dart';

/// 当前窗口的多窗口启动参数；主窗口为 null，子窗口由启动时 override。
@Riverpod(keepAlive: true)
DesktopMultiWindowArgs? multiWindowArgs(Ref ref) => null;
