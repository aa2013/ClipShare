import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

const _advancedRegistryPath = r'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';
const _disabledHotkeysValueName = 'DisabledHotkeys';
const _winVDisabledHotkey = 'V';

/// 读取 Windows Explorer 当前是否通过注册表禁用了 Win+V。
Future<bool> isWinVDisabled() async {
  if (!Platform.isWindows) return false;
  final key = Registry.openPath(RegistryHive.currentUser, path: _advancedRegistryPath);
  try {
    final value = key.getStringValue(_disabledHotkeysValueName) ?? '';
    return _containsWinVDisabledHotkey(value);
  } finally {
    key.close();
  }
}

/// 在 DisabledHotkeys 中追加 V，仅在原值未包含 V 时写回注册表。
Future<bool> takeOverWinV() async {
  if (!Platform.isWindows) return false;
  final key = Registry.openPath(
    RegistryHive.currentUser,
    path: _advancedRegistryPath,
    desiredAccessRights: AccessRights.allAccess,
  );
  try {
    final value = key.getStringValue(_disabledHotkeysValueName) ?? '';
    if (_containsWinVDisabledHotkey(value)) {
      return false;
    }
    key.createValue(RegistryValue.string(_disabledHotkeysValueName, '$value$_winVDisabledHotkey'));
    return true;
  } finally {
    key.close();
  }
}

/// 从 DisabledHotkeys 中移除 V，仅保留其他被禁用的系统快捷键字符。
Future<bool> restoreWinV() async {
  if (!Platform.isWindows) return false;
  final key = Registry.openPath(
    RegistryHive.currentUser,
    path: _advancedRegistryPath,
    desiredAccessRights: AccessRights.allAccess,
  );
  try {
    final value = key.getStringValue(_disabledHotkeysValueName) ?? '';
    if (!_containsWinVDisabledHotkey(value)) {
      return false;
    }
    final restored = _removeWinVDisabledHotkey(value);
    if (restored.isEmpty) {
      key.deleteValue(_disabledHotkeysValueName);
    } else {
      key.createValue(RegistryValue.string(_disabledHotkeysValueName, restored));
    }
    return true;
  } finally {
    key.close();
  }
}

/// 重启 Explorer，让 DisabledHotkeys 变更立即生效。
Future<void> restartExplorer() async {
  if (!Platform.isWindows) return;
  await Process.run('taskkill', ['/F', '/IM', 'explorer.exe'], runInShell: true);
  await Process.start('explorer.exe', const [], mode: ProcessStartMode.detached);
}

/// 统一按大小写无关方式判断 DisabledHotkeys 是否包含 V。
bool _containsWinVDisabledHotkey(String value) {
  return value.toUpperCase().contains(_winVDisabledHotkey);
}

/// 移除所有大小写形式的 V，避免重复或旧值大小写差异导致恢复不完整。
String _removeWinVDisabledHotkey(String value) {
  return value.split('').where((char) => char.toUpperCase() != _winVDisabledHotkey).join();
}
