import 'dart:async';

import 'package:clipshare/features/guide/models/guide_state.dart';
import 'package:clipshare/features/guide/providers/guide_bootstrap_provider.dart';
import 'package:clipshare/features/guide/providers/guide_step_handler_provider.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guide_controller_provider.g.dart';

/// 引导流程控制。
///
/// 只维护「当前步骤」与「各步骤完成状态」；翻页动画与路由跳转属于页面职责，
/// 不放进状态，避免 UI 对象跟随 provider 生命周期存活。
@riverpod
class GuideController extends _$GuideController {
  static const tag = 'GuideController';

  /// 当前步骤下标。
  ///
  /// 单独保存是为了在依赖刷新导致 [build] 重新执行时保留用户已完成的进度。
  int _currentIndex = 0;

  @override
  GuideState build() {
    final bootstrap = ref.watch(guideBootstrapProvider).value;
    // 步骤清单尚未组装完成时保持空清单，此时页面只展示加载态。
    if (bootstrap == null) {
      return const GuideState(steps: []);
    }
    // 完成状态刷新不应打断用户进度，步骤清单变化时才按新下标范围收敛当前位置。
    _currentIndex = _currentIndex.clamp(0, bootstrap.steps.length - 1);
    return GuideState(
      steps: bootstrap.steps,
      completed: bootstrap.completed,
      currentIndex: _currentIndex,
    );
  }

  /// 切换到指定下标的步骤，下标越界时忽略。
  void goTo(int index) {
    final state = this.state;
    if (index < 0 || index >= state.steps.length || index == state.currentIndex) {
      return;
    }
    _currentIndex = index;
    this.state = state.copyWith(currentIndex: index);
    unawaited(refreshCurrent());
  }

  /// 重新查询当前步骤的完成状态。
  ///
  /// 用户可能刚从系统设置页返回，权限结果已变化，需要重新判定。
  Future<void> refreshCurrent() async {
    if (state.steps.isEmpty) {
      return;
    }
    final id = state.currentStepId;
    final handler = await ref.read(guideStepHandlerProvider(id).future);
    if (handler == null) {
      return;
    }
    bool completed;
    try {
      completed = await handler.hasPermission();
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return;
    }
    // 查询期间用户可能已经切换步骤，过期结果不再回写。
    if (state.currentStepId != id || state.isCompleted(id) == completed) {
      return;
    }
    state = state.copyWith(
      completed: {...state.completed, id: completed},
    );
  }
}