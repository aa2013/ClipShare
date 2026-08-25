import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/providers/startup/app_startup_provider.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/constants/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  /// 标记启动成功后的跳转是否已经触发，避免监听回调重复执行页面替换。
  bool _hasNavigatedToHome = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<void>>(appStartupProvider, _handleStartupChanged);
  }

  /// 启动完成后统一切到主控制台；失败状态交给当前页面展示错误即可。
  void _handleStartupChanged(AsyncValue<void>? previous, AsyncValue<void> next) {
    if (_hasNavigatedToHome || next is! AsyncData<void>) {
      return;
    }
    //todo 如果是Android 需要跳转到引导页
    _hasNavigatedToHome = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.replaceNamed(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(appStartupProvider);
    return Scaffold(
      body: SafeArea(
        child: switch (startup) {
          AsyncLoading() => _buildLoadingWidget(),
          AsyncData() => _buildLoadingWidget(),
          AsyncError(:final error, :final stackTrace) => _buildErrorWidget(
            error,
            stackTrace,
          ),
        },
      ),
    );
  }

  /// 初始化完成前继续展示启动页，避免路由替换前出现空白闪烁。
  Widget _buildLoadingWidget() {
    return Center(
      child: Image.asset(
        logoPngPath,
        width: 100,
        height: 100,
      ),
    );
  }

  /// 启动失败时保留当前错误展示，便于桌面端直接复制异常详情排查问题。
  Widget _buildErrorWidget(dynamic err, dynamic stack) {
    if (isDesktop) {
      windowManager.show();
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Text('Initialization failed! Error: $err'),
              Tooltip(
                message: 'Copy error detail',
                child: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$err\n$stack'));
                  },
                  icon: const Icon(
                    Icons.copy,
                    color: Colors.blueGrey,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(stack.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
