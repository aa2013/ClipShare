import 'package:clipshare/app/modules/db_editor_module/db_editor_controller.dart';
import 'package:flutter_embed_lua/lua_runtime.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DebugController extends GetxController {
  final selected = false.obs;
  final visibleCharacterCount = 0.obs;
  final showBorder = false.obs;
  final ntfListening = false.obs;
  final enableBlacklist = true.obs;
  final lua = LuaRuntime();
}
