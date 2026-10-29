import 'guide_step.dart';

/// 引导流程状态。
///
/// 完成状态以 [completed] 映射统一记录，页面展示、按钮可用性与底部指示器
/// 全部由该状态派生，避免多处各自维护一份权限结果。
class GuideState {
  /// 参与本次引导的步骤清单，顺序即页面展示顺序。
  final List<GuideStepSpec> steps;

  /// 当前步骤下标，始终落在 [steps] 范围内。
  final int currentIndex;

  /// 各步骤完成状态；未命中的步骤视为未完成。
  final Map<GuideStep, bool> completed;

  const GuideState({
    required this.steps,
    this.currentIndex = 0,
    this.completed = const {},
  });

  /// 当前步骤描述。
  GuideStepSpec get currentStep => steps[currentIndex];

  /// 当前步骤标识。
  GuideStep get currentStepId => currentStep.step;

  /// 当前步骤是否已授权/已选择。
  bool get currentCompleted => completed[currentStep.step] ?? false;

  /// 是否为最后一步。
  bool get isLastStep => currentIndex == steps.length - 1;

  /// 是否允许前进：已完成或该步骤允许跳过。
  bool get canAdvance => currentCompleted || currentStep.skippable;

  /// 是否展示「跳过」按钮：仅在允许跳过且尚未完成时展示，
  bool get showSkip => currentStep.skippable && !currentCompleted;

  /// 指定步骤是否完成。
  bool isCompleted(GuideStep id) => completed[id] ?? false;

  /// 切换到指定下标的步骤
  GuideState copyWith({int? currentIndex, Map<GuideStep, bool>? completed}) {
    return GuideState(
      steps: steps,
      currentIndex: currentIndex ?? this.currentIndex,
      completed: completed ?? this.completed,
    );
  }
}