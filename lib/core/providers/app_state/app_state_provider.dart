import 'package:clipshare/core/providers/app_state/app_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'app_state_provider.g.dart';

/// 运行时配置
@Riverpod(keepAlive: true)
class AppStateNotifier extends _$AppStateNotifier {
  @override
  AppState build(){
    return const AppState();
  }

  /// 批量覆盖整个运行时配置
  void update(AppState value) {
    state = value;
  }

  /// 更新规则迁移状态
  void updateRulesMigrated(bool value) {
    state = state.copyWith(rulesMigrated: value);
  }

  /// 更新中转服务版本号
  void updateTransportServerVersion(String value) {
    state = state.copyWith(transportServerVersion: value);
  }

  /// 更新当前网络类型
  void updateNetWorkType(ConnectivityResult type) {
    state = state.copyWith(currentNetWorkType: type);
  }

  /// 更新是否是小屏幕
  void updateIsSmallScreen(bool value) {
    state = state.copyWith(isSmallScreen: value);
  }

  /// 更新是否正在选择工作模式
  void updateSelectingWorkingMode(bool value) {
    state = state.copyWith(selectingWorkingMode: value);
  }

  /// 更新是否启用多选模式
  void updateEnableMultiSelectionMode(bool value) {
    state = state.copyWith(isEnableMultiSelectionMode: value);
  }

  /// 更新是否鉴权中
  void updateAuthenticating(bool value) {
    state = state.copyWith(authenticating: value);
  }

  /// 更新设备发现状态描述文本
  void updateDeviceDiscoveryStatus(String? value) {
    state = state.copyWith(deviceDiscoveryStatus: value);
  }

  /// 更新加密密钥
  void updateDhAesKey(String? value) {
    state = state.copyWith(dhAesKey: value);
  }

  /// 更新是否忽略无障碍权限缺失提示
  void updateIgnoreAccessibility(bool value) {
    state = state.copyWith(ignoreAccessibility: value);
  }
}
