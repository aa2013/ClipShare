import 'package:clipshare/features/history/pages/preview_page.dart';
import 'package:clipshare/features/home/pages/home_page.dart';
import 'package:clipshare/features/segment_words/pages/segment_words_page.dart';
import 'package:clipshare/features/splash/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// 应用统一路由配置，承接启动页与主控制台之间的切换。
final appRouter = GoRouter(
  initialLocation: AppRoutes.splash.path,
  routes: [
    GoRoute(
      path: AppRoutes.splash.path,
      name: AppRoutes.splash.name,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.home.path,
      name: AppRoutes.home.name,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.imagePreview.path,
      name: AppRoutes.imagePreview.name,
      builder: (context, state) {
        final args = state.extra as PreviewRouteArgs;
        return PreviewPage(
          history: args.history,
          onlyView: args.onlyView,
          single: args.single,
        );
      },
    ),
    // 分词页以非不透明整页叠加在来源页面之上，供 BackdropFilter 采样实现高斯模糊背景
    GoRoute(
      path: AppRoutes.segmentWords.path,
      name: AppRoutes.segmentWords.name,
      pageBuilder: (context, state) {
        final args = state.extra as SegmentWordsRouteArgs;
        return CustomTransitionPage(
          opaque: false,
          child: SegmentWordsPage(text: args.text),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );
      },
    ),
  ],
);
