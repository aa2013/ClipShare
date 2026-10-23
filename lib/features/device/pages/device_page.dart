import 'dart:async';
import 'dart:math';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/device/device_provider.dart';
import 'package:clipshare/core/services/device/events/device_discovery_event.dart';
import 'package:clipshare/core/services/device/events/device_lifecycle_event.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/transport/enums/msg_type.dart';
import 'package:clipshare/core/services/transport/socket/discovery/discovery_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/reconnect_provider.dart';
import 'package:clipshare/core/services/transport/socket/session/session_provider.dart';
import 'package:clipshare/core/services/transport/storage/storage_provider.dart';
import 'package:clipshare/core/settings/device/device_paried_filter_status.dart';
import 'package:clipshare/core/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/settings/forward/forward_server_status.dart';
import 'package:clipshare/core/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/features/device/widgets/network_address_dialog.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/consumer_wrapper.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/network_util.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:clipshare/shared/widgets/base/loading_dots.dart';
import 'package:clipshare/shared/widgets/base/tiny_segmented_control.dart';
import 'package:clipshare/shared/widgets/dot.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../widgets/add_device_dialog.dart';
import '../widgets/device_card.dart';
import '../widgets/device_platform_icon.dart';
import '../widgets/pairing_pin_dialog.dart';

class DevicePage extends ConsumerStatefulWidget {
  const DevicePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DevicePageState();
}

class _DevicePageState extends ConsumerState<DevicePage> with TickerProviderStateMixin {
  static const tag = 'DevicePage';
  late AnimationController rotationController;
  var rotationReverse = false;
  late Animation<double> animation;
  StreamSubscription<DeviceDiscoveryEvent>? _discoveryEventsSubscription;
  DeviceNotifier get deviceNotifier => ref.read(deviceProvider.notifier);
  SessionNotifier get sessionNotifier => ref.read(sessionProvider.notifier);
  DeviceState get deviceState => ref.read(deviceProvider).requireValue;

  @override
  void initState() {
    rotationController = AnimationController(
      vsync: this,
      duration: 4.s,
    );

    setRotationAnimation();
    // 通过设备发现生命周期事件驱动动画，避免页面状态与发现令牌状态分叉。
    _discoveryEventsSubscription = deviceNotifier.discoveryEvents.listen(_onDiscoveryEvent);
    super.initState();
  }

  /// 根据当前方向更新发现按钮的旋转动画。
  void setRotationAnimation() {
    final anim = Tween<double>(
      begin: 0.0,
      end: 1 * (rotationReverse ? -1 : 1),
    ).animate(rotationController);
    animation = anim;
  }

  /// 根据发现生命周期事件启动或停止按钮动画。
  void _onDiscoveryEvent(DeviceDiscoveryEvent event) {
    if (!mounted) {
      return;
    }
    if (event is DeviceDiscoveryStarted) {
      rotationReverse = !rotationReverse;
      setRotationAnimation();
      rotationController.repeat();
    }
    else if (event is DeviceDiscoveryFinished) {
      rotationController.stop();
      rotationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.currentTheme;
    final isDark = context.isDarkMode;
    final dbProvider = ref.read(appDbProvider).requireValue;
    final configDao = dbProvider.configDao;
    final pairedList = ref.watch(deviceProvider.select((state) => state.requireValue.pairedList));
    final discoveryList = ref.watch(deviceProvider.select((state) => state.requireValue.discoveryList));
    final discovering = ref.watch(discoveryProvider);
    final filterStatus = ref.watch(deviceSettingsProvider.select((state) => state.requireValue.pairedStatusFilter));
    final forwardStatus = ref.watch(appStateProvider.select((state) => state.forwardServerStatus));
    final forwardSettings = ref.watch(forwardSettingsProvider).requireValue;
    final sktService = ref.read(discoveryProvider.notifier);
    return ListView(
      children: [
        Column(
          children: <Widget>[
            //我的设备列表
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: Visibility(
                    visible: pairedList.isNotEmpty,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.devices_rounded),
                            const SizedBox(width: 5),
                            Text(
                              TranslationKey.devicePageMyDevicesText.trParams({
                                'length': pairedList.length.toString(),
                              }),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            TinySegmentedControl(
                              initialSelected: DevicePairedStatusFilter.values.indexOf(filterStatus),
                              options: DevicePairedStatusFilter.values.map((status) {
                                return Tooltip(
                                  message: status.tr,
                                  child: InkWell(
                                    mouseCursor: SystemMouseCursors.click,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(status.icon, size: 15),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onSelected: (int index) async {
                                final filter = DevicePairedStatusFilter.values[index];
                                await configDao.addOrUpdate(ConfigKey.devicePairedStatusFilter, filter.name);
                                ref.invalidate(deviceSettingsProvider);
                              },
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                              segmentSpacing: 2,
                              padding: EdgeInsets.zero,
                              backgroundColor: isDark ? theme.cardTheme.color ?? theme.colorScheme.surfaceBright : null,
                              selectedBackgroundColor: isDark ? theme.colorScheme.primary.withValues(alpha: 0.20) : null,
                              selectedColor: isDark ? theme.colorScheme.onSurface : Colors.blue,
                              unselectedColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.62 : 0.70),
                            ),
                          ],
                        ),
                        Offstage(
                          offstage: !forwardSettings.enable,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 5),
                                child: Dot(
                                  radius: 6.0,
                                  color: forwardStatus.color,
                                ),
                              ),
                              Text(TranslationKey.devicePageForwardServerText.tr),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (pairedList.isNotEmpty) consumerWrapper(renderPairedList),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.online_prediction_rounded,
                    color: discovering ? Colors.blueGrey : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    TranslationKey.devicePageDiscoverDevicesText.trParams({
                      'length': discoveryList.length.toString(),
                    }),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    tooltip: TranslationKey.devicePageRediscoverTooltip.tr,
                    onPressed: () {
                      final discovery = ref.read(discoveryProvider.notifier);
                      if (discovering) {
                        discovery.restartDiscoveryDevices();
                      } else {
                        discovery.startDiscoveryDevices(manual: true);
                      }
                    },
                    icon: ExcludeSemantics(
                      child: RotationTransition(
                        turns: animation,
                        child: const Icon(
                          Icons.sync,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: TranslationKey.devicePageManuallyTooltip.tr,
                    child: IconButton(
                      onPressed: () {
                        dialogManager.open(context, const AddDeviceDialog(), dismissible: false);
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: discovering,
                    child: Tooltip(
                      message: TranslationKey.devicePageStopDiscoveringTooltip.tr,
                      child: IconButton(
                        onPressed: () {
                          sktService.stopDiscoveryDevices();
                        },
                        icon: const Icon(
                          Icons.stop,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: consumerWrapper(renderDeviceDiscoveryStatus)),
                ],
              ),
            ),
            consumerWrapper(renderDiscoveryList),

            //查看本机IP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    final interfaces = await NetworkUtil.listInterfaces();
                    for (var itf in interfaces) {
                      // itf.addresses[0].type
                      logger.debug(tag, "${itf.name} ${itf.addresses.join(',')}");
                    }
                    if (context.mounted) {
                      dialogManager.open(
                        context,
                        NetworkAddressDialog(
                          interfaces: interfaces,
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(
                        MdiIcons.web,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(TranslationKey.showLocalIpAddress.tr),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget renderDeviceDiscoveryStatus(BuildContext context, WidgetRef ref) {
    final deviceDiscoveryStatus = ref.watch(appStateProvider.select((state) => state.deviceDiscoveryStatus));
    if (deviceDiscoveryStatus.isNullOrEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: LoadingDots(text: Text(deviceDiscoveryStatus!)),
      ),
    );
  }

  /// 渲染已配对设备列表，并根据筛选状态构造全部设备卡片。
  Widget renderPairedList(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(deviceSettingsProvider).requireValue;
    final deviceState = ref.watch(deviceProvider).requireValue;
    final filteredDevices = getFilteredPairedList(settings.pairedStatusFilter, deviceState);
    if (filteredDevices.isEmpty) {
      return const EmptyContent();
    }
    final selfVersion = ref.read(localDeviceInfoProvider).requireValue.appVersion;
    final registry = deviceState.registry;
    final reconnectingGuids = ref.watch(reconnectProvider);
    final connectingGuids = ref.watch(deviceConnectingProvider);
    final cards = filteredDevices
        .map((device) {
          final protocol = registry.getProtocol(device.guid) ?? .direct;
          return DeviceCard(
            device: device,
            isPaired: true,
            isConnected: registry.getProtocol(device.guid) != null,
            protocol: protocol,
            targetVersion: registry.getVersion(device.guid),
            minVersion: registry.getMinVersion(device.guid),
            selfVersion: selfVersion,
            selfMinVersion: minVersion,
            isReconnecting: reconnectingGuids.contains(device.guid),
            isConnecting: connectingGuids.contains(device.guid),
            onTap: (value, connected) => _onDeviceCardTap(value, connected, protocol),
            onLongPress: (value, connected) => _onDeviceCardLongPress(value, connected, protocol),
            onRenameButtonClicked: (value) => _showRenameDialog(context, value),
          );
        })
        .toList(growable: false);
    return renderGridView(cards);
  }

  /// 渲染发现列表；发现为空时显示设备卡片的占位动画。
  Widget renderDiscoveryList(BuildContext context, WidgetRef ref) {
    final discoveryList = ref.watch(deviceProvider.select((state) => state.requireValue.discoveryList));
    final selfVersion = ref.read(localDeviceInfoProvider).requireValue.appVersion;
    if (discoveryList.isEmpty) {
      return DeviceCard(
        device: null,
        isPaired: false,
        isConnected: false,
        minVersion: null,
        targetVersion: null,
        selfVersion: selfVersion,
        selfMinVersion: minVersion,
        protocol: TransportProtocol.direct,
        onRenameButtonClicked: (_) {},
      );
    }
    final cards = discoveryList
        .map((devInfo) {
          final storedDevice = deviceState.getStoredById(devInfo.guid);
          final displayDevice =
              storedDevice ??
              Device(
                guid: devInfo.guid,
                devName: devInfo.name,
                uid: 0,
                type: devInfo.type.value,
                isPaired: false,
              );
          final registry = deviceState.registry;
          final protocol = registry.getProtocol(displayDevice.guid) ?? .direct;
          return DeviceCard(
            device: displayDevice,
            isPaired: false,
            isConnected: true,
            protocol: protocol,
            targetVersion: registry.getVersion(displayDevice.guid),
            minVersion: registry.getMinVersion(displayDevice.guid),
            selfVersion: selfVersion,
            selfMinVersion: minVersion,
            onTap: (_, __) => _requestPairing(devInfo, context),
            onRenameButtonClicked: (_) {},
          );
        })
        .toList(growable: false);
    return renderGridView(cards);
  }

  /// 根据屏幕宽度和用户偏好排列设备卡片。
  Widget renderGridView(List<DeviceCard> list) {
    return LayoutBuilder(
      builder: (context, constraints) => Consumer(
        builder: (context, ref, child) {
          const maxCardWidth = 395;
          final showMoreItems = ref.watch(preferenceSettingsProvider.select((state) => state.requireValue.showMoreItemsInRow));
          final showMore = showMoreItems && !context.isCompactScreen;
          final columns = showMore && list.length >= 2 ? max(2, constraints.maxWidth ~/ maxCardWidth) : 1;
          return MasonryGridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) => list[index],
          );
        },
      ),
    );
  }

  /// 按当前偏好将已配对设备分为全部、在线和离线三类。
  List<Device> getFilteredPairedList(DevicePairedStatusFilter filter, DeviceState deviceState) {
    switch (filter) {
      case .all:
        return deviceState.pairedList;
      case .online:
        return deviceState.onlineAndPairedList;
      case .offline:
        final pairedList = deviceState.pairedList;
        final onlineIds = deviceState.onlineAndPairedList.map((device) => device.guid).toSet();
        return pairedList.where((device) => !onlineIds.contains(device.guid)).toList();
    }
  }

  /// 保存设备自定义名称，并刷新 Riverpod 设备状态
  Future<void> _showRenameDialog(BuildContext context, Device device) async {
    DialogController? dlgCtl;
    dlgCtl = dialogManager.open(
      context,
      _DeviceRenameDialog(
        device: device,
        onClose: () => dlgCtl?.close(),
        onSave: (name) => deviceNotifier.addOrUpdate(
          device.copyWith(customName: Value(name)),
        ),
      ),
    );
    await dlgCtl.future;
  }

  /// 桌面端点击设备卡片时显示操作面板。
  void _onDeviceCardTap(Device device, bool isConnected, TransportProtocol protocol) {
    if (!isDesktop || !mounted) return;
    _showBottomDetailSheet(device, isConnected, protocol);
  }

  /// 移动端长按设备卡片时显示操作面板。
  void _onDeviceCardLongPress(Device device, bool isConnected, TransportProtocol protocol) {
    if (!isMobile || !mounted) return;
    _showBottomDetailSheet(device, isConnected, protocol);
  }

  /// 显示设备连接、同步和取消配对操作。
  Future<void> _showBottomDetailSheet(Device device, bool isConnected, TransportProtocol protocol) async {
    final storage = ref.read(storageProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        final baseInfo = BaseDeviceInfo.fromDevice(device);
        return SafeArea(
          child: SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DevicePlatformIcon(
                          platform: PlatformType(device.type),
                          isConnected: isConnected,
                          size: 58,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.displayName, style: const TextStyle(fontSize: 25)),
                            Text(device.address ?? '', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _detailAction(
                          icon: Icons.edit_note_rounded,
                          label: TranslationKey.rename.tr,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showRenameDialog(context, device);
                          },
                        ),
                      ),
                      Expanded(
                        child: _detailAction(
                          icon: isConnected ? Icons.link_off : Icons.link,
                          label: isConnected ? TranslationKey.devicePageDisconnect.tr : TranslationKey.devicePageReconnect.tr,
                          onTap: () async {
                            if (isConnected) {
                              if (protocol.isSocket) {
                                await sessionNotifier.disconnectDevice(baseInfo, true);
                              } else {
                                storage.disconnectDevice(device.guid);
                              }
                            } else if (protocol.isSocket) {
                              unawaited(_reconnectWithFeedback(device));
                            } else {
                              storage.connectDevice(device.guid);
                            }
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                      Expanded(
                        child: _detailAction(
                          icon: Icons.block_flipped,
                          label: TranslationKey.devicePageUnpairedButtonText.tr,
                          onTap: () async {
                            final confirmed = await _confirmForget(sheetContext);
                            if (!confirmed) return;
                            if (protocol.isSocket) {
                              await sessionNotifier.forgetDevice(baseInfo);
                              // 设备在线时通知对端同步解除配对，避免对端仍显示为已配对
                              if (isConnected) {
                                try {
                                  await sessionNotifier.sendData(baseInfo, MsgType.forgetDev, {});
                                } catch (err, stack) {
                                  logger.debug(tag, 'send forgetDev failed. device=${baseInfo.guid}, $err $stack');
                                }
                              }
                            } else {
                              await deviceNotifier.confirmPairingState(
                                device: device,
                                localIsPaired: false,
                                remoteIsPaired: false,
                                protocol: protocol,
                                manual: true,
                              );
                            }
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                      if (isConnected)
                        Expanded(
                          child: _detailAction(
                            icon: Icons.sync_rounded,
                            label: TranslationKey.syncData.tr,
                            onTap: () {
                              snackbar.success(context, TranslationKey.syncingData.tr);
                              sessionNotifier.requestMissingData(device.guid);
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 异步执行一次手动重连，完成后按连接状态提示成功或失败
  Future<void> _reconnectWithFeedback(Device device) async {
    final reconnectNotifier = ref.read(reconnectProvider.notifier);
    await reconnectNotifier.reconnectOnce(device.guid);
    if (!mounted) {
      return;
    }
    final registry = deviceState.registry;
    if (registry.getProtocol(device.guid) != null) {
      snackbar.success(
        context,
        TranslationKey.deviceReconnectSuccess.trParams({
          'devName': device.displayName,
        }),
      );
    } else {
      snackbar.error(
        context,
        TranslationKey.deviceReconnectFailed.trParams({
          'devName': device.displayName,
        }),
      );
    }
  }

  /// 构造详情面板中的统一操作按钮。
  Widget _detailAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(children: [Icon(icon), Text(label)]),
      ),
    );
  }

  /// 显示取消配对确认框
  Future<bool> _confirmForget(BuildContext context) async {
    var confirmed = false;
    final dialog = await dialogManager.tips(
      context,
      text: TranslationKey.devicePageUnpairedDialogContent.tr,
      actions: DialogActions(
        cancel: const DialogAction(),
        confirm: DialogAction(onPressed: () => confirmed = true),
      ),
    );
    await dialog?.future;
    return confirmed;
  }

  /// 向发现设备发起配对请求并显示六位验证码输入框。
  /// 配对结果由弹窗自身监听生命周期事件处理：成功关闭弹窗，失败清空重输。
  Future<void> _requestPairing(BaseDeviceInfo device, BuildContext context) async {
    final sessions = sessionNotifier;
    await sessions.sendData(device, MsgType.reqPairing, {}, false);
    if (!context.mounted) {
      return;
    }

    DialogController? dlgCtl;
    dlgCtl = dialogManager.open(
      context,
      PairingPinDialog(
        onClose: () => dlgCtl?.close(),
        pairingResults: deviceNotifier.lifecycleEvents
            .where((event) {
              if (event is! DevicePaired) {
                return false;
              }
              return event.device.guid == device.guid;
            })
            .cast<DevicePaired>(),
        cancelSignal: deviceNotifier.lifecycleEvents
            .where((event) {
              if (event is! DevicePairingCanceled) {
                return false;
              }
              return event.device.guid == device.guid;
            })
            .cast<DevicePairingCanceled>(),
        onSendCode: (code) => sessions.sendData(
          device,
          MsgType.pairing,
          {'code': CryptoUtil.toMD5(code)},
          false,
        ),
        onCancel: () => sessions.cancelPairing(device),
      ),
      dismissible: false,
    );
    await dlgCtl.future;
  }

  @override
  void dispose() {
    _discoveryEventsSubscription?.cancel();
    rotationController.dispose();
    super.dispose();
  }
}

/// 设备重命名弹窗：自身管理输入控制器，保存成功后才关闭。
class _DeviceRenameDialog extends StatefulWidget {
  final Device device;

  /// 保存自定义名称，返回是否保存成功。
  final Future<bool> Function(String name) onSave;

  /// 关闭弹窗回调
  final VoidCallback onClose;

  const _DeviceRenameDialog({
    required this.device,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_DeviceRenameDialog> createState() => _DeviceRenameDialogState();
}

class _DeviceRenameDialogState extends State<_DeviceRenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.device.customName ?? '',
  );

  /// 保存请求进行中，期间禁止重复提交与取消。
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 保存自定义名称；保存成功前保持弹窗打开。
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final success = await widget.onSave.call(_controller.text.trim());
    if (success && context.mounted) {
      widget.onClose();
    } else {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationKey.rename.tr),
      content: SizedBox(
        width: 300,
        child: TextField(
          autofocus: true,
          controller: _controller,
          decoration: InputDecoration(
            label: Text(TranslationKey.pleaseInput.tr),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : widget.onClose,
          child: Text(TranslationKey.dialogCancelText.tr),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(TranslationKey.save.tr),
        ),
      ],
    );
  }
}
