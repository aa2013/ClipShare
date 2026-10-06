
/// 同步事件来源，替代旧链路中 fromStorage / loadingMissingData 两个布尔标记的组合。
enum SyncSource {
  /// 在线单条 sync
  direct,

  /// 在线批量补数（missingData）
  missingData,

  /// 存储实时回放
  storage,

  /// 存储补拉
  storageMissing,
}