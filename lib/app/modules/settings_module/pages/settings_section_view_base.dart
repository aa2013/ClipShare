import 'package:clipshare/app/modules/rules_module/rules_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_section.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

export 'dart:convert';
export 'dart:io' hide HeaderValue;
export 'package:clipshare/app/data/enums/forward_server_status.dart';
export 'package:clipshare/app/data/enums/hot_key_type.dart';
export 'package:clipshare/app/data/enums/translation_key.dart';
export 'package:clipshare/app/handlers/hot_key_handler.dart';
export 'package:clipshare/app/modules/home_module/home_controller.dart';
export 'package:clipshare/app/modules/settings_module/settings_section.dart';
export 'package:clipshare/app/routes/app_pages.dart';
export 'package:clipshare/app/services/android_notification_listener_service.dart';
export 'package:clipshare/app/services/channels/android_channel.dart';
export 'package:clipshare/app/services/clipboard_service.dart';
export 'package:clipshare/app/services/config_service.dart';
export 'package:clipshare/app/services/transport/socket_service.dart';
export 'package:clipshare/app/services/transport/storage_service.dart';
export 'package:clipshare/app/services/tray_service.dart';
export 'package:clipshare/app/utils/constants.dart';
export 'package:clipshare/app/utils/extensions/clipboard_listener_way_extension.dart';
export 'package:clipshare/app/utils/extensions/keyboard_key_extension.dart';
export 'package:clipshare/app/utils/extensions/number_extension.dart';
export 'package:clipshare/app/utils/extensions/platform_extension.dart';
export 'package:clipshare/app/utils/extensions/string_extension.dart';
export 'package:clipshare/app/utils/extensions/translation_key_extension.dart';
export 'package:clipshare/app/utils/file_util.dart';
export 'package:clipshare/app/utils/global.dart';
export 'package:clipshare/app/utils/log.dart';
export 'package:clipshare/app/utils/permission_helper.dart';
export 'package:clipshare/app/widgets/clip/clip_data_copy_icon_button.dart';
export 'package:clipshare/app/widgets/dialog/forward_server_edit_dialog.dart';
export 'package:clipshare/app/widgets/dialog/hot_key_editor_dialog.dart';
export 'package:clipshare/app/widgets/dialog/multi_select_dialog.dart';
export 'package:clipshare/app/widgets/dialog/notification_server_edit_dialog.dart';
export 'package:clipshare/app/widgets/dialog/outdate_time_input_dialog.dart';
export 'package:clipshare/app/widgets/dialog/qr_image_dialog.dart';
export 'package:clipshare/app/widgets/dialog/s3_config_edit_dialog.dart';
export 'package:clipshare/app/widgets/dialog/single_select_dialog.dart';
export 'package:clipshare/app/widgets/dialog/text_edit_dialog.dart';
export 'package:clipshare/app/widgets/dialog/webdav_config_edit_dialog.dart';
export 'package:clipshare/app/widgets/dot.dart';
export 'package:clipshare/app/widgets/settings/card/setting_card.dart';
export 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
export 'package:clipshare_clipboard_listener/clipboard_manager.dart';
export 'package:clipshare_clipboard_listener/enums.dart';
export 'package:file_picker/file_picker.dart';
export 'package:flutter_colorpicker/flutter_colorpicker.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:flutter_context_menu/flutter_context_menu.dart';
export 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
export 'package:get/get.dart';
export 'package:launch_at_startup/launch_at_startup.dart';
export 'package:notification_listener_service/notification_listener_service.dart';
export 'package:open_file_plus/open_file_plus.dart';
export 'package:package_info_plus/package_info_plus.dart';
export 'package:permission_handler/permission_handler.dart' show openAppSettings;
export 'package:clipshare/app/data/enums/forward_way.dart';

abstract class SettingsSectionView extends GetView<SettingsController> {
  final SettingsSection section;
  final bool embedded;

  SettingsSectionView({
    super.key,
    required this.section,
    this.embedded = false,
  });

  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final storageService = Get.find<StorageService>();
  final ruleController = Get.find<RulesController>();
  final logTag = "SettingsPage";

  final arrowForwardIcon = const Icon(
    Icons.arrow_forward_rounded,
    color: Colors.blueGrey,
  );

  // Each concrete page owns one first-level settings section.
  bool get showGroupHeader => false;

  List<SettingEntry> buildSettingEntries(BuildContext context) => const [];

  List<Widget> buildCards(BuildContext context);

  List<SettingsSearchItem> buildSearchItems(BuildContext context) {
    return buildSettingEntries(context)
        .where((entry) => entry.visible && (entry.searchKeys.isNotEmpty || entry.searchAliases.isNotEmpty))
        .map((entry) {
          return SettingsSearchItem(
            section: section,
            searchId: entry.searchId,
            searchKeys: entry.searchKeys,
            searchAliases: entry.searchAliases,
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(),
        RefreshIndicator(
          child: Padding(
            padding: embedded ? const EdgeInsets.fromLTRB(18, 8, 18, 18) : const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: ListView(
              children: [
                ...buildCards(context),
                const SizedBox(height: 10),
              ],
            ),
          ),
          onRefresh: () {
            controller.update();
            return Future.value();
          },
        ),
      ],
    );
  }
}
