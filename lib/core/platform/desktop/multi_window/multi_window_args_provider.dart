import 'package:clipshare/shared/models/desktop_multi_window_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multi_window_args_provider.g.dart';

/// 当前窗口的多窗口启动参数；主窗口为 null，子窗口由启动时 override。
// todo 子窗口入口迁移完成后，必须在子窗口 ProviderContainer 创建处 override 本 provider，
// 否则子窗口会因拿到 null 而被当作主窗口处理（配置推送、标题栏行为均会异常）。
@Riverpod(keepAlive: true)
DesktopMultiWindowArgs? multiWindowArgs(Ref ref) => null;
