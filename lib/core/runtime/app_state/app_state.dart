import 'package:connectivity_plus/connectivity_plus.dart';

/// 应用启动初始化状态
enum AppInitStatus {
  /// 尚未开始初始化
  uninitialized,

  /// 正在初始化
  initializing,

  /// 已完成初始化
  initialized,
}

///ClipShare 运行时配置
class AppState {
  ///规则是否已经迁移
  final bool rulesMigrated;

  ///中转服务版本号
  final String transportServerVersion;

  ///当前网络类型
  final ConnectivityResult currentNetWorkType;

  ///是否正在选择工作模式
  final bool selectingWorkingMode;

  ///是否启用多选模式
  final bool isEnableMultiSelectionMode;

  ///是否鉴权中
  final bool authenticating;

  ///设备发现状态描述文本
  final String? deviceDiscoveryStatus;


  ///当前是否忽略无障碍权限缺失提示
  final bool ignoreAccessibility;

  ///当前是否忽略shizuku权限
  final bool ignoreShizuku;

  ///应用启动初始化状态
  final AppInitStatus initStatus;

  const AppState({
    this.rulesMigrated = false,
    this.transportServerVersion = '',
    this.currentNetWorkType = ConnectivityResult.none,
    this.selectingWorkingMode = false,
    this.isEnableMultiSelectionMode = false,
    this.authenticating = false,
    this.deviceDiscoveryStatus,
    this.ignoreAccessibility = false,
    this.ignoreShizuku = false,
    this.initStatus = AppInitStatus.uninitialized,
  });

  AppState copyWith({
    bool? rulesMigrated,
    String? transportServerVersion,
    ConnectivityResult? currentNetWorkType,
    bool? isSmallScreen,
    bool? selectingWorkingMode,
    bool? isEnableMultiSelectionMode,
    bool? authenticating,
    String? deviceDiscoveryStatus,
    String? dhAesKey,
    bool? ignoreAccessibility,
    bool? ignoreShizuku,
    AppInitStatus? initStatus,
  }) {
    return AppState(
      rulesMigrated: rulesMigrated ?? this.rulesMigrated,
      transportServerVersion: transportServerVersion ?? this.transportServerVersion,
      currentNetWorkType: currentNetWorkType ?? this.currentNetWorkType,
      selectingWorkingMode: selectingWorkingMode ?? this.selectingWorkingMode,
      isEnableMultiSelectionMode: isEnableMultiSelectionMode ?? this.isEnableMultiSelectionMode,
      authenticating: authenticating ?? this.authenticating,
      deviceDiscoveryStatus: deviceDiscoveryStatus ?? this.deviceDiscoveryStatus,
      ignoreAccessibility: ignoreAccessibility ?? this.ignoreAccessibility,
      ignoreShizuku: ignoreShizuku ?? this.ignoreShizuku,
      initStatus: initStatus ?? this.initStatus,
    );
  }
}
