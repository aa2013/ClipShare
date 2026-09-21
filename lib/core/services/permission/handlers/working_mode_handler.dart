import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';

import 'abstract_permission_handler.dart';

/// 工作模式选择步骤的处理器。
///
/// 完成条件是「用户已明确选定工作模式」：配置表中存在 workingMode 记录，
/// 且选定的是特权环境时该环境已授权。
/// 这里读取原始记录而不是解析后的剪贴板配置，因为 [EnvironmentType.none]
/// 既是合法选择（忽略模式）也是未配置时的默认值，只有记录是否存在
/// 能区分「尚未选择」与「主动选择忽略」。
class WorkingModeHandler extends AbstractPermissionHandler {
  /// 配置表沿用单用户约定，uid 固定为 0。
  static const int configUid = 0;

  final ConfigDao _configDao;

  WorkingModeHandler(this._configDao);

  /// 选择动作由工作模式选择卡片直接发起，这里无需再拉起系统授权界面。
  @override
  Future<void> request(BuildContext context) async {}

  @override
  Future<bool> hasPermission() async {
    final raw = await _configDao.getConfig(
      ConfigKey.workingMode.name,
      configUid,
    );
    if (raw == null) {
      return false;
    }
    final mode = EnvironmentType.parse(raw);
    return switch (mode) {
      EnvironmentType.shizuku || EnvironmentType.root => clipboardManager.checkPermission(mode),
      _ => true,
    };
  }
}
