import 'package:clipshare/app/utils/network_interface_filter_util.dart';
import 'package:clipshare/app/widgets/empty_content.dart';

import 'settings_section_view_base.dart';

class SettingsConnectivityPage extends SettingsSectionView {
  SettingsConnectivityPage({super.key, super.embedded}) : super(section: SettingsSection.connectivity);

  @override
  List<Widget> buildCards(BuildContext context) {
    return [
      Obx(
        () => SettingCardGroup(
          showHeader: showGroupHeader,
          groupName: TranslationKey.discoveringSettingsGroupName.tr,
          icon: const Icon(Icons.wifi),
          cardList: buildSettingEntries(context),
        ),
      ),
    ];
  }

  @override
  List<SettingEntry> buildSettingEntries(BuildContext context) {
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
                        ClipboardData(
                          text: appConfig.devInfo.guid,
                        ),
                      );
                      Global.showSnackBarSuc(
                        context: context,
                        text: TranslationKey.discoveringSettingsDeviceNameCopyTip.tr,
                      );
                    },
                    tooltip: TranslationKey.copyDeviceId.tr,
                  ),
                ],
              ),
              description: Text(
                "id: ${appConfig.devInfo.guid}",
              ),
              value: appConfig.localName,
              action: (v) => Text(v),
              onTap: () {
                Global.showDialog(
                  context,
                  TextEditDialog(
                    title: TranslationKey.modifyDeviceName.tr,
                    labelText: TranslationKey.deviceName.tr,
                    initStr: appConfig.localName,
                    onOk: (str) {
                      appConfig.setLocalName(str);
                      Global.showSnackBarSuc(
                        context: context,
                        text: TranslationKey.modifyDeviceNameCompletedTooltip.tr,
                      );
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
              description: Text(TranslationKey.discoveringSettingsPortDesc.tr),
              value: appConfig.port,
              action: (v) => Text(v.toString()),
              onTap: () {
                Global.showDialog(
                  context,
                  TextEditDialog(
                    title: TranslationKey.modifyPort.tr,
                    labelText: TranslationKey.port.tr,
                    initStr: appConfig.port.toString(),
                    verify: (str) {
                      var port = int.tryParse(str);
                      if (port == null) return false;
                      return port >= 0 && port <= 65535;
                    },
                    errorText: TranslationKey.modifyPortErrorText.tr,
                    onOk: (str) {
                      appConfig.setPort(str.toInt());
                      Global.showSnackBarSuc(
                        context: context,
                        text: TranslationKey.discoveringSettingsModifyPortCompletedTooltip.tr,
                      );
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
              value: appConfig.allowDiscover,
              action: (v) => Switch(
                value: v,
                onChanged: (checked) {
                  HapticFeedback.mediumImpact();
                  appConfig.setAllowDiscover(checked);
                  sktService.disConnectAllConnections(true);
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
              value: appConfig.onlyForwardMode,
              action: (v) => Switch(
                value: v,
                onChanged: (checked) {
                  HapticFeedback.mediumImpact();
                  appConfig.setOnlyForwardMode(checked);
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
                      onTap: () async {
                        Global.showTipsDialog(
                          context: context,
                          text: TranslationKey.discoveringSettingsHeartbeatIntervalTooltipDialogContent.tr,
                        );
                      },
                    ),
                  ),
                ],
              ),
              description: Text(TranslationKey.discoveringSettingsHeartbeatIntervalDesc.tr),
              value: appConfig.heartbeatInterval,
              action: (v) => Text(v <= 0 ? TranslationKey.dontDetect.tr : '${v}s'),
              onTap: () {
                Global.showDialog(
                  context,
                  TextEditDialog(
                    title: TranslationKey.discoveringSettingsModifyHeartbeatDialogTitle.tr,
                    labelText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputLabel.tr,
                    initStr: "${appConfig.heartbeatInterval <= 0 ? '' : appConfig.heartbeatInterval}",
                    verify: (str) {
                      var port = int.tryParse(str);
                      if (port == null) return false;
                      return true;
                    },
                    errorText: TranslationKey.discoveringSettingsModifyHeartbeatDialogInputErrorText.tr,
                    onOk: (str) async {
                      await appConfig.setHeartbeatInterval(str);
                      var enable = str.toInt() > 0;
                      if (enable) {
                        sktService.startHeartbeatTest();
                      } else {
                        sktService.stopHeartbeatTest();
                      }
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
              value: appConfig.autoCloseConnAfterScreenOff,
              show: (v) => Platform.isAndroid,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    HapticFeedback.mediumImpact();
                    appConfig.setAutoCloseConnAfterScreenOff(checked);
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
              value: appConfig.enableAutoSyncOnScreenOpened,
              show: (v) => Platform.isAndroid,
              action: (v) {
                return Switch(
                  value: v,
                  onChanged: (checked) async {
                    HapticFeedback.mediumImpact();
                    appConfig.setEnableAutoSyncOnScreenOpened(checked);
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
              value: appConfig.onlyManualDiscoverySubNet,
              action: (v) {
                return Switch(
                  value: appConfig.onlyManualDiscoverySubNet,
                  onChanged: (checked) {
                    HapticFeedback.mediumImpact();
                    appConfig.setOnlyManualDiscoverySubNet(checked);
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
              value: appConfig.noDiscoveryIfs,
              action: (v) {
                return TextButton(
                  child: Text(TranslationKey.configure.tr),
                  onPressed: () async {
                    final interfaces = await NetworkInterfaceFilterUtil.listInterfaces();
                    if (!context.mounted) {
                      return;
                    }
                    if (interfaces.isEmpty) {
                      Global.showDialog(
                        context,
                        AlertDialog(
                          title: Text(TranslationKey.noDiscoveryIfsSettingTitle.tr),
                          content: SizedBox(
                            width: 280,
                            height: 180,
                            child: Center(
                              child: EmptyContent(size: 80),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back();
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
                    dialog = MultiSelectDialog.show(
                      context: context,
                      dismissable: true,
                      onSelected: (List<String> values) {
                        Future.delayed(100.ms).then(
                          (value) {
                            appConfig.setNoDiscoveryIfs(values);
                            dialog!.close();
                          },
                        );
                      },
                      defaultValues: appConfig.noDiscoveryIfs,
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
