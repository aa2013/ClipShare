/// 操作记录同步载荷的组装结果。
class SyncPayload {
  /// 本地记录对应的实体已不存在且操作不是删除，发送方应清理该记录。
  final bool shouldRemove;

  /// 完整同步消息载荷：操作记录元数据 + 业务实体载荷。
  final Map<String, dynamic> data;

  const SyncPayload({required this.shouldRemove, required this.data});
}
