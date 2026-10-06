import 'dart:io';

import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/extensions/multi_select_dialog_extension.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:clipshare/features/history/widgets/copy_icon_button.dart';
import 'package:clipshare/features/settings/enums/settings_section.dart';
import 'package:clipshare/features/settings/pages/settings_section_view_base.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card_group.dart';
import 'package:clipshare/features/settings/widgets/card/setting_entry.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/dialogs/multi_select_dialog.dart';
import 'package:clipshare/shared/widgets/dialogs/text_edit_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsDiscoveryPage extends SettingsSectionView {
  const SettingsDiscoveryPage({super.key, super.embedded}) : super(section: SettingsSection.discovery);

  @override
  List<Widget> buildCards(BuildContext context, WidgetRef ref) {
    return [
      SettingCardGroup(
        showHeader: showGroupHeader,
        groupName: TranslationKey.discoveringSettingsGroupName.tr,
        icon: const Icon(Icons.wifi),
        cardList: buildSettingEntries(context, ref),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context, WidgetRef ref) {
    final localDevice = ref.watch(localDeviceInfoProvider).requireValue;
    final discoverySettings = ref.watch(discoverySettingsProvider).requireValue;
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    final selfDev = localDevice.baseDeviceInfo;
    final localName = localDevice.localName;
    return [
      SettingCard(
        searchKeys: const [
          TranslationKey.discoveringSettingsLocalDeviceName,
          TranslationKey.copyDeviceId,
          TranslationKey.modifyDeviceName,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.discoveringSettingsLocalDeviceName.tr,
              maxLines: 1,
            ),
            const SizedBox(width: 5),
            CopyIconButton(
              onClick: () {
                HapticFeedback.mediumImpact();
                Clipboard.setData(
                  ClipboardData(text: selfDev.guid),
                );
                snackbar.success(
                  context,
                  TranslationKey.discoveringSettingsDeviceNameCopyTip.tr,
                );
              },
              tooltip: TranslationKey.copyDeviceId.tr,
            ),
          ],
        ),
        description: Text('id: ${selfDev.guid}'),
        value: localName,
        action: (v) => Text(v),
        onTap: () {
          dialogManager.open(
            context,
            TextEditDialog(
              title: TranslationKey.modifyDeviceName.tr,
              labelText: TranslationKey.deviceName.tr,
              initStr: localName,
              onOk: (str) async {
                await configDao.addOrUpdate(.localName, str);
                ref.invalidate(localDeviceInfoProvider);
                if (context.mounted) {
                  snackbar.success(
                    context,
                    TranslationKey.modifyDeviceNameCompletedTooltip.tr,
                  );
                }
              },
            ),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.port,
          TranslationKey.discoveringSettingsPortDesc,
          TranslationKey.modifyPort,
        ],
        title: Text(
          TranslationKey.port.tr,
          maxLines: 1,
        ),
        description: Text(
          TranslationKey.discoveringSettingsPortDesc.trParams(
            {
              'port': net.port.toString(),
            },
          ),
        ),
        value: discoverySettings.port,
        action: (v) => Text(v.toString()),
        onTap: () {
          dialogManager.open(
            context,
            TextEditDialog(
              title: TranslationKey.modifyPort.tr,
              labelText: TranslationKey.port.tr,
              initStr: discoverySettings.port.toString(),
              verify: (str) {
                var port = int.tryParse(str);
                if (port == null) return false;
                return port >= 0 && port <= 65535;
              },
              errorText: TranslationKey.modifyPortErrorText.tr,
              onOk: (str) async {
                final _ = str.toInt();
                await configDao.addOrUpdate(.port, str);
                ref.invalidate(discoverySettingsProvider);
                if (context.mounted) {
                  snackbar.success(
                    context,
                    TranslationKey.discoveringSettingsModifyPortCompletedTooltip.tr,
                  );
                }
              },
            ),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.allowDiscovering,
          TranslationKey.discoveringSettingsAllowDiscoveringDesc,
        ],
        title: Text(
          TranslationKey.allowDiscovering.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.discoveringSettingsAllowDiscoveringDesc.tr),
        value: discoverySettings.allowDiscovery,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.allowDiscover, checked.toString());
            ref.invalidate(discoverySettingsProvider);
            //todo
            // sktService.disConnectAllConnections(true);
          },
        ),
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.discoveringSettingsOnlyForwardDiscoveringTitle,
          TranslationKey.discoveringSettingsOnlyForwardDiscoveringDesc,
        ],
        title: Text(
          TranslationKey.discoveringSettingsOnlyForwardDiscoveringTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.discoveringSettingsOnlyForwardDiscoveringDesc.tr),
        value: discoverySettings.onlyForwardMode,
        action: (v) => Switch(
          value: v,
          onChanged: (checked) async {
            await HapticFeedback.mediumImpact();
            await configDao.addOrUpdate(.onlyForwardMode, checked.toString());
            ref.invalidate(discoverySettingsProvider);
            if (!checked) return;
            //todo
            // return sktService.disConnectAllConnections();
          },
        ),
        show: (v) => !kReleaseMode,
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.discoveringSettingsHeartbeatIntervalTitle,
          TranslationKey.discoveringSettingsHeartbeatIntervalDesc,
          TranslationKey.discoveringSettingsHeartbeatIntervalTooltip,
        ],
        title: Row(
          children: [
            Text(
              TranslationKey.discoveringSettingsHeartbeatIntervalTitle.tr,
              maxLines: 1,
            ),
            const SizedBox(
              width: 5,
            ),
            Tooltip(
              message: TranslationKey.discoveringSettingsHeartbeatIntervalTooltip.tr,
              child: GestureDetector(
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                    size: 15,
                  ),
                ),
                onTap: () {
                  dialogManager.tips(
                    context,
                    text: TranslationKey.discoveringSettingsHeartbeatIntervalDialogContent.tr,
                  );
                },
              ),
            ),
          ],
        ),
        description: Text(TranslationKey.discoveringSettingsHeartbeatIntervalDesc.tr),
        value: discoverySettings.heartbeatInterval,
        action: (v) => Text(v <= 0 ? TranslationKey.dontDetect.tr : '${v}s'),
        onTap: () {
          dialogManager.open(
            context,
            TextEditDialog(
              title: TranslationKey.discoveringSettingsModifyHeartbeatDialogTitle.tr,
              labelText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputLabel.tr,
              initStr: "${discoverySettings.heartbeatInterval <= 0 ? '' : discoverySettings.heartbeatInterval}",
              verify: (str) {
                var port = int.tryParse(str);
                if (port == null) return false;
                return true;
              },
              errorText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputErrorText.tr,
              onOk: (str) async {
                final _ = str.toInt();
                await configDao.addOrUpdate(.heartbeatInterval, str);
                var enable = str.toInt() > 0;
                if (enable) {
                  //todo
                  // sktService.startHeartbeatTest();
                } else {
                  //todo
                  // sktService.stopHeartbeatTest();
                }
                ref.invalidate(discoverySettingsProvider);
              },
            ),
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.syncAutoCloseSettingTitle,
          TranslationKey.syncAutoCloseSettingDesc,
        ],
        title: Text(
          TranslationKey.syncAutoCloseSettingTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.syncAutoCloseSettingDesc.tr),
        value: discoverySettings.autoCloseConnAfterScreenOff,
        show: (v) => Platform.isAndroid,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(
                .autoCloseConnAfterScreenOff,
                checked.toString(),
              );
              ref.invalidate(discoverySettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.enableAutoSyncOnScreenOpenedTitle,
          TranslationKey.enableAutoSyncOnScreenOpenedDesc,
        ],
        title: Text(
          TranslationKey.enableAutoSyncOnScreenOpenedTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.enableAutoSyncOnScreenOpenedDesc.tr),
        value: discoverySettings.enableAutoSyncOnScreenOpened,
        show: (v) => Platform.isAndroid,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.enableAutoSyncOnScreenOpened, checked.toString());
              ref.invalidate(discoverySettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.keepConnectionsOnNetworkSwitchTitle,
          TranslationKey.keepConnectionsOnNetworkSwitchDesc,
        ],
        title: Text(
          TranslationKey.keepConnectionsOnNetworkSwitchTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.keepConnectionsOnNetworkSwitchDesc.tr),
        value: discoverySettings.keepConnectionsOnNetworkSwitch,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.keepConnectionsOnNetworkSwitch, checked.toString());
              ref.invalidate(discoverySettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.onlyManualDiscoverySubNetSettingTitle,
          TranslationKey.onlyManualDiscoverySubNetSettingDesc,
        ],
        title: Text(
          TranslationKey.onlyManualDiscoverySubNetSettingTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.onlyManualDiscoverySubNetSettingDesc.tr),
        value: discoverySettings.onlyManualDiscoverySubNet,
        action: (v) {
          return Switch(
            value: v,
            onChanged: (checked) async {
              await HapticFeedback.mediumImpact();
              await configDao.addOrUpdate(.onlyManualDiscoverySubNet, checked.toString());
              ref.invalidate(discoverySettingsProvider);
            },
          );
        },
      ),
      SettingCard(
        searchKeys: const [
          TranslationKey.noDiscoveryIfsSettingTitle,
          TranslationKey.noDiscoveryIfsSettingDesc,
        ],
        title: Text(
          TranslationKey.noDiscoveryIfsSettingTitle.tr,
          maxLines: 1,
        ),
        description: Text(TranslationKey.noDiscoveryIfsSettingDesc.tr),
        value: discoverySettings.noDiscoveryIfs,
        action: (v) {
          return TextButton(
            child: Text(TranslationKey.configure.tr),
            onPressed: () async {
              final interfaces = await NetworkUtil.listInterfaces();
              if (!context.mounted) {
                return;
              }
              if (interfaces.isEmpty) {
                late final DialogController dialog;
                dialog = dialogManager.open(
                  context,
                  AlertDialog(
                    title: Text(TranslationKey.noDiscoveryIfsSettingTitle.tr),
                    content: const SizedBox(
                      width: 280,
                      height: 180,
                      child: Center(
                        child: EmptyContent(size: 80),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          dialog.close();
                        },
                        child: Text(TranslationKey.dialogConfirmText.tr),
                      ),
                    ],
                  ),
                );
                return;
              }
              final selections = interfaces.map((itf) {
                var showTextList = [itf.name];
                var ipList = itf.addresses.where((address) => address.type == InternetAddressType.IPv4).map((address) => address.address);
                showTextList.addAll(ipList);
                return CheckboxData(value: itf.name, text: showTextList.join('\n'));
              }).toList();
              DialogController? dialog;
              dialog = showMultiSelectDialog(
                context: context,
                dismissable: true,
                onSelected: (List<String> values) async {
                  await Future.delayed(100.ms);
                  await configDao.addOrUpdate(.noDiscoveryIfs, values.join(','));
                  ref.invalidate(discoverySettingsProvider);
                  await dialog!.close();
                },
                defaultValues: discoverySettings.noDiscoveryIfs,
                minSelectedCnt: 0,
                selections: selections,
                textStyle: const TextStyle(fontSize: 13),
                title: Text(TranslationKey.noDiscoveryIfsSettingTitle.tr),
              );
            },
          );
        },
      ),
    ];
  }
}
