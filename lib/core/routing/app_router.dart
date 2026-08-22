import 'package:clipshare/core/routing/app_routes.dart';
import 'package:clipshare/features/home/pages/main_console_page.dart';
import 'package:clipshare/features/splash/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      builder: (context, state) => const MainConsolePage(),
    ),
  ],
);
