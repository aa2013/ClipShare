import 'package:clipshare/features/home/pages/home_page.dart';
import 'package:clipshare/features/splash/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// 应用统一路由配置，承接启动页与主控制台之间的切换。
final appRouter = GoRouter(
  initialLocation: '/${AppRoutes.splash}',
  routes: [
    GoRoute(
      path: '/${AppRoutes.splash}',
      name: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/${AppRoutes.home}',
      name: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),
  ],
);
