import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/features/app_selection/app_selection_entry.dart';
import 'package:clipshare/features/guide/pages/user_guide_page.dart';
import 'package:clipshare/features/history/pages/preview_page.dart';
import 'package:clipshare/features/home/pages/home_page.dart';
import 'package:clipshare/features/rules/pages/rule_detail.dart';
import 'package:clipshare/features/rules/pages/rules_page.dart';
import 'package:clipshare/features/rules/pages/script_module_detail.dart';
import 'package:clipshare/features/segment_words/pages/segment_words_page.dart';
import 'package:clipshare/features/settings/pages/settings_section_content.dart';
import 'package:clipshare/features/splash/pages/splash_page.dart';
import 'package:clipshare/features/tags/pages/tag_edit_page.dart';
import 'package:clipshare/features/working_mode_selection/pages/working_mode_selection_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// 应用统一路由配置，承接启动页与主控制台之间的切换。
final appRouter = GoRouter(
  navigatorKey: navigatorKey,
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
    GoRoute(
      path: AppRoutes.tagEdit.path,
      name: AppRoutes.tagEdit.name,
      builder: (context, state) {
        final args = state.extra as TagEditRouteArgs;
        return TagEditPage(hisId: args.hisId);
      },
    ),
    GoRoute(
      path: AppRoutes.rules.path,
      name: AppRoutes.rules.name,
      builder: (context, state) => const RulesPage(),
    ),
    GoRoute(
      path: AppRoutes.ruleDetail.path,
      name: AppRoutes.ruleDetail.name,
      builder: (context, state) => const RuleDetail(),
    ),
    GoRoute(
      path: AppRoutes.scriptModuleDetail.path,
      name: AppRoutes.scriptModuleDetail.name,
      builder: (context, state) => const ScriptModuleDetail(),
    ),
    GoRoute(
      path: AppRoutes.appSelection.path,
      name: AppRoutes.appSelection.name,
      builder: (context, state) {
        final args = state.extra as AppSelectionRouteArgs;
        return args.buildPage();
      },
    ),
    GoRoute(
      path: AppRoutes.userGuide.path,
      name: AppRoutes.userGuide.name,
      builder: (context, state) => const UserGuidePage(),
    ),
    GoRoute(
      path: AppRoutes.settingsSection.path,
      name: AppRoutes.settingsSection.name,
      builder: (context, state) {
        final args = state.extra as SettingsSectionRouteArgs;
        return SettingsSectionContentPage(
          section: args.section,
          highlightedSearchId: args.highlightedSearchId,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.workingModeSelection.path,
      name: AppRoutes.workingModeSelection.name,
      builder: (context, state) => const WorkingModeSelectionPage(),
    ),
  ],
);
