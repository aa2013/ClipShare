import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';

enum HotKeyType {
  showMainWindows,
  exitApp,
  historyWindow,
  fileSender;

  String? get hotKeyDesc {
    final hotKey = AppHotKeyHandler.getByType(this);
    return hotKey?.desc;
  }
}
