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
