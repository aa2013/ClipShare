import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/features/guide/models/guide_state.dart';
import 'package:clipshare/features/guide/providers/guide_bootstrap_provider.dart';
import 'package:clipshare/features/guide/providers/guide_controller_provider.dart';
import 'package:clipshare/features/guide/widgets/guide_progress_indicator.dart';
import 'package:clipshare/features/guide/widgets/guide_step_body.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/widgets/loading/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 用户引导页。
///
/// 步骤清单与初始完成状态由 [guideBootstrapProvider] 组装，页面只负责展示与翻页交互。
class UserGuidePage extends ConsumerStatefulWidget {
  const UserGuidePage({super.key});

  @override
  ConsumerState<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends ConsumerState<UserGuidePage> with WidgetsBindingObserver {
  /// 页面内边距。
  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(10, 5, 10, 10);

  /// 翻页动画时长。
  static const int _pageAnimationMilliseconds = 200;

  /// 「下一步 / 完成」按钮的固定宽度，避免文案长度变化引起底部栏抖动。
  static const double _forwardButtonWidth = 70;

  /// 加载态指示器尺寸。
  static const double _loadingSize = 48;

  final PageController _pageController = PageController();

  /// 标记跳转主界面是否已经触发，避免一帧内重复跳转。
  bool _hasNavigatedToHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  /// 回到前台时重新判定当前步骤，避免从系统设置页返回后按钮状态滞后。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final guideController = ref.read(guideControllerProvider.notifier);
    guideController.refreshCurrent();
  }

  /// 跳转到主界面，重复触发只生效一次。
  Future<void> _gotoHome() async {
    if (_hasNavigatedToHome) {
      return;
    }
    _hasNavigatedToHome = true;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(ConfigKey.firstStartup, true.toString());
    ref.invalidate(localDeviceInfoProvider);
    if (mounted) {
      context.goNamed(AppRoutes.home.name);
    }
  }

  /// 「跳过」与「下一步 / 完成」的统一处理。
  void _handleForward() {
    final guideState = ref.read(guideControllerProvider);
    if (!guideState.canAdvance) {
      return;
    }
    if (guideState.isLastStep) {
      _gotoHome();
      return;
    }
    _pageController.nextPage(
      duration: _pageAnimationMilliseconds.ms,
      curve: Curves.ease,
    );
  }

  /// 返回上一步，首页时不做处理。
  void _handleBackward() {
    if (ref.read(guideControllerProvider).currentIndex == 0) {
      return;
    }
    _pageController.previousPage(
      duration: _pageAnimationMilliseconds.ms,
      curve: Curves.ease,
    );
  }

  /// 同步翻页结果；未完成当前步骤时禁止越级前进。
  void _handlePageChanged(int index) {
    final guideState = ref.read(guideControllerProvider);
    if (index > guideState.currentIndex && !guideState.canAdvance) {
      _pageController.previousPage(
        duration: _pageAnimationMilliseconds.ms,
        curve: Curves.ease,
      );
      return;
    }
    final guideController = ref.read(guideControllerProvider.notifier);
    guideController.goTo(index);
  }

  /// 步骤清单组装完成且仍有必须完成的步骤时展示引导，否则回到主界面。
  void _syncGuideEntry(GuideBootstrap? bootstrap) {
    if (bootstrap == null || bootstrap.shouldRunGuide) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _gotoHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(guideBootstrapProvider).asData?.value;
    final guideState = ref.watch(guideControllerProvider);
    _syncGuideEntry(bootstrap);
    return Scaffold(
      body: SafeArea(
        child: bootstrap == null ? _buildLoading() : _buildGuide(guideState),
      ),
    );
  }

  /// 步骤清单尚未组装完成时的加载态。
  Widget _buildLoading() {
    // return const Center(
    //   child: SizedBox(
    //     width: _loadingSize,
    //     height: _loadingSize,
    //     child: CircularProgressIndicator(strokeWidth: 3),
    //   ),
    // );
    return const Loading(width: _loadingSize);
  }

  /// 引导主体：顶部跳过入口 + 步骤页 + 底部操作栏。
  Widget _buildGuide(GuideState guideState) {
    return Padding(
      padding: _pagePadding,
      child: Column(
        children: [
          _buildSkipAction(guideState),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _handlePageChanged,
              children: [
                for (final step in guideState.steps)
                  Center(
                    child: SingleChildScrollView(
                      child: GuideStepBody(
                        step: step,
                        onEnterApp: _gotoHome,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomBar(guideState),
        ],
      ),
    );
  }

  /// 顶部跳过入口；当前步骤已完成时不展示，避免与「下一步」重复。
  ///
  /// 按钮位置固定保留，不可用时只清空文案，防止步骤切换时整页纵向抖动。
  Widget _buildSkipAction(GuideState guideState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: guideState.showSkip ? _handleForward : null,
          child: Text(
            guideState.showSkip ? TranslationKey.skipGuide.tr : '',
          ),
        ),
      ],
    );
  }

  /// 底部「上一步 + 指示器 + 下一步」操作栏。
  Widget _buildBottomBar(GuideState guideState) {
    return Row(
      children: [
        TextButton(
          onPressed: guideState.currentIndex == 0 ? null : _handleBackward,
          child: Text(TranslationKey.previousGuide.tr),
        ),
        Expanded(
          child: GuideProgressIndicator(
            total: guideState.steps.length,
            current: guideState.currentIndex,
          ),
        ),
        SizedBox(
          width: _forwardButtonWidth,
          child: TextButton(
            onPressed: guideState.canAdvance ? _handleForward : null,
            child: Text(
              guideState.isLastStep ? TranslationKey.finishGuide.tr : TranslationKey.nextGuide.tr,
            ),
          ),
        ),
      ],
    );
  }
}
