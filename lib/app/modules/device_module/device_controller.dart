import 'package:clipshare/app/data/enums/device_paried_filter_status.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/handlers/sync/storage_sync_record_helper.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/device_remove_listener.dart';
import 'package:clipshare/app/listeners/discover_listener.dart';
import 'package:clipshare/app/listeners/forward_status_listener.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/device/device_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DeviceController extends GetxController with GetSingleTickerProviderStateMixin implements DevAliveListener, DeviceRemoveListener, SyncListener, DiscoverListener, ForwardStatusListener {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final sktService = Get.find<SocketService>();
  final storageService = Get.find<StorageService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();

  //region 属性
  final String tag = "DevicesPage";
  final discoverList = List<DeviceCard>.empty(growable: true).obs;
  final pairedList = List<DeviceCard>.empty(growable: true).obs;

  List<DeviceCard> get filteredPairedList {
    return pairedList.where((item) {
      final v = appConfig.devicePairedStatusFilter;
      if (v == DevicePairedStatusFilter.all) {
        return true;
      }
      if (v == DevicePairedStatusFilter.online && item.isConnected) {
        return true;
      }
      if (v == DevicePairedStatusFilter.offline && !item.isConnected) {
        return true;
      }
      return false;
    }).toList();
  }

  ///获取在线且配对的设备列表
  List<Device> get onlineAndPairedList => pairedList.where((item) => item.isConnected).map((item) => item.dev!).toList(growable: false);

  ///获取离线且配对的设备列表
  List<Device> get offlineAndPairedList => pairedList.where((item) => !item.isConnected).map((item) => item.dev!).toList(growable: false);

  ///获取在线设备列表
  List<Device> get onlineList => [...pairedList, ...discoverList].where((item) => item.isConnected).map((item) => item.dev!).toList(growable: false);

  ///获取兼容版本的在线设备列表
  List<Device> get compatibleOnlineDevices => pairedList.where((item) => item.isVersionCompatible && item.isConnected).map((item) => item.dev!).toList(growable: false);
  late StateSetter pairingState;
  final pairingFailed = false.obs;
  final pairing = false.obs;
  bool newPairing = false;
  final discovering = true.obs;
  final forwardStatus = ForwardServerStatus.disconnected.obs;
  late AnimationController _rotationController;
  final rotationReverse = false.obs;
  late Rx<Animation<double>> animation;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    connRegService.addDevAliveListener(this);
    connRegService.addDiscoverListener(this);
    connRegService.addForwardStatusListener(this);
    DataSender.addSyncListener(Module.device, this);
    devService.addDevRemoveListener(this);
    // 旋转动画
    _rotationController = AnimationController(
      vsync: this,
      duration: 4.s,
    )..repeat();
    setRotationAnimation(true);
    dbService.deviceDao.getAllDevices(appConfig.userId).then((list) {
      pairedList.clear();
      for (var dev in list) {
        if (!dev.isPaired) {
          continue;
        }
        pairedList.add(
          DeviceCard(
            dev: dev,
            isPaired: true,
            onTap: (device, isConnected, showReNameDlg) => _onDeviceCardTap(device, isConnected, showReNameDlg),
            onLongPress: (device, isConnected, showReNameDlg) => _onDeviceCardLongPress(device, isConnected, showReNameDlg),
            isConnected: false,
            isSelf: false,
            minVersion: null,
            version: null,
            protocol: TransportProtocol.direct,
          ),
        );
      }
      pairedList.sort((a, b) => a.dev!.displayName.compareTo(b.dev!.displayName));
    });
  }

  @override
  void onClose() {
    connRegService.removeDevAliveListener(this);
    connRegService.removeDiscoverListener(this);
    connRegService.removeForwardStatusListener(this);
    DataSender.removeSyncListener(Module.device, this);
    devService.removeDevRemoveListener(this);
    _rotationController.dispose();
    super.onClose();
  }

  //endregion

  //region 监听与同步
  @override
  Future ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = newOperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) {
    var data = <dynamic, dynamic>{};
    if (msg.data["data"] is Map) {
      data = msg.data["data"];
      msg.data["data"] = "";
    }
    var opRecord = operationRecordFromJson(msg.data);
    Map<String, dynamic> json = data.cast();
    Device dev = Device.fromJson(json);
    Future f = Future(() => null);
    if (dev.guid != appConfig.devInfo.guid) {
      switch (opRecord.method) {
        case OpMethod.add:
          f = dbService.deviceDao.add(dev);
          break;
        case OpMethod.delete:
          devService.remove(dev.guid);
          break;
        case OpMethod.update:
          f = dbService.deviceDao.updateDevice(dev);
          break;
        default:
          return Future.value();
      }
    }
    return f;
  }

  @override
  Future<void> onStorageSync(Map<String, dynamic> map, Device sender, bool loadingMissingData) async {
    var data = <dynamic, dynamic>{};
    if (map["data"] is Map) {
      // 设备对象本身放在 data 里，opRecord 反序列化前要先把它从 map 中拆出来。
      data = map["data"];
      map["data"] = "";
    }
    final opRecord = StorageSyncRecordHelper.fromStorageMap(map);
    final json = data.cast<String, dynamic>();
    final dev = Device.fromJson(json);
    if (dev.guid == appConfig.devInfo.guid) {
      // 存储目录里也会看到自己的设备元数据，直接跳过避免把自己当成远端设备写回。
      return;
    }

    var success = false;
    switch (opRecord.method) {
      case OpMethod.add:
        success = await dbService.deviceDao.add(dev) > 0;
        break;
      case OpMethod.delete:
        success = await devService.remove(dev.guid);
        break;
      case OpMethod.update:
        success = await dbService.deviceDao.updateDevice(dev) > 0;
        break;
      default:
        return;
    }
    if (!success) {
      return;
    }
    await dbService.opRecordDao.add(
      // 设备记录是由存储回放写入的，本地 opRecord 也必须保持 storageSync=true。
      StorageSyncRecordHelper.copyWithStorageData(opRecord, dev.guid),
    );
  }

  @override
  void onConnected(
    DevInfo info,
    AppVersion minVersion,
    AppVersion version,
    TransportProtocol protocol,
  ) async {
    final dev = await deviceFromDevInfo(info);
    final displayDev = dev ??
        Device(
          guid: info.guid,
          devName: info.name,
          uid: 0,
          type: info.type,
          isPaired: false,
        );
    for (var i = 0; i < pairedList.length; i++) {
      var paired = pairedList[i];
      if (paired.dev?.guid == info.guid) {
        // 只更新已配对列表里的连接态，不再用协议强行改变配对事实。
        pairedList[i] = paired.copyWith(
          isConnected: true,
          dev: displayDev,
          minVersion: minVersion,
          version: version,
          protocol: protocol,
        );
        _notifyOnlineDevicesWindow();
        return;
      }
    }
    discoverList.removeWhere((element) => element.dev?.guid == info.guid);
    if (displayDev.isPaired) {
      pairedList.add(
        DeviceCard(
          dev: displayDev,
          isPaired: true,
          isConnected: true,
          isSelf: false,
          minVersion: minVersion,
          version: version,
          protocol: protocol,
          onTap: (device, isConnected, showReNameDlg) => _onDeviceCardTap(device, isConnected, showReNameDlg),
          onLongPress: (device, isConnected, showReNameDlg) => _onDeviceCardLongPress(device, isConnected, showReNameDlg),
        ),
      );
      pairedList.sort((a, b) => a.dev!.displayName.compareTo(b.dev!.displayName));
      return;
    }
    discoverList.add(
      DeviceCard(
        dev: displayDev,
        onTap: (device, isConnected, showReNameDlg) => _requestPairing(info, Get.context!),
        minVersion: minVersion,
        version: version,
        isPaired: false,
        isConnected: true,
        isSelf: false,
        protocol: protocol,
      ),
    );
  }

  @override
  void onDisconnected(String devId) {
    discoverList.removeWhere((dev) => dev.dev?.guid == devId);
    for (var i = 0; i < pairedList.length; i++) {
      var dev = pairedList[i];
      if (dev.dev?.guid == devId) {
        pairedList[i] = dev.copyWith(
          isConnected: false,
          minVersion: null,
          version: null,
          protocol: TransportProtocol.direct,
        );
      }
    }
    _notifyOnlineDevicesWindow();
  }

  @override
  void onDiscoverStart() {
    _rotationController.repeat();
    discovering.value = true;
    logger.debug(tag, "onDiscoverStart");
  }

  @override
  void onDiscoverFinished() {
    discovering.value = false;
    logger.debug(tag, "onDiscoverFinished");
    rotationReverse.value = false;
    setRotationAnimation();
    _rotationController.stop();
  }

  @override
  void onForget(DevInfo dev, int uid) {
    //忘记设备，从已配对列表移动到发现设备列表
    var forgetDev = pairedList.firstWhereOrNull(
      (element) => element.dev?.guid == dev.guid,
    );
    pairedList.removeWhere(
      (element) => element.dev?.guid == dev.guid,
    );
    forgetDev = forgetDev?.copyWith(isPaired: false);
    if (forgetDev?.isConnected ?? false) {
      discoverList.removeWhere((element) => element.dev?.guid == dev.guid);
      discoverList.add(
        forgetDev!.copyWith(
          isPaired: false,
          onTap: (device, isConnected, showReNameDlg) => _requestPairing(dev, Get.context!),
        ),
      );
    }
    _notifyOnlineDevicesWindow();
  }

  @override
  void onForwardServerStatusChanged(ForwardServerStatus status) {
    forwardStatus.value = status;
  }

  @override
  void onPaired(DevInfo dev, int uid, bool result, String? address) async {
    if (!result) {
      logger.debug(tag, "_pairingFailed $pairingFailed");
      pairingFailed.value = true;
      pairing.value = false;
      pairingState(() {});
      return;
    }
    //关闭配对弹窗
    Get.back();
    newPairing = false;
    final pairedDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    if (pairedDev == null || !pairedDev.isPaired) {
      logger.debug(tag, "Device information addition failed");
      Global.showSnackBarErr(context: Get.context!, text: TranslationKey.deviceAdditionFailedDialogText.tr);
      return;
    }
    _addPairedDevInPage(pairedDev);
    //已配对，请求所有缺失数据
    sktService.reqMissingData();
  }

  @override
  void onCancelPairing(DevInfo dev) {
    if (!newPairing) return;
    newPairing = false;
    Get.back();
  }

  @override
  void onRemove(String devId) {
    print("removeDevice $devId");
    pairedList.removeWhere((dev) => dev.dev?.guid == devId);
  }

  //endregion

  //region 页面方法

  void _onDeviceCardTap(Device device, bool isConnected, void Function() showReNameDlg) {
    if (PlatformExt.isDesktop) {
      _showBottomDetailSheet(
        device,
        isConnected,
        showReNameDlg,
        Get.context!,
        device.protocol,
      );
    }
  }

  void _onDeviceCardLongPress(Device device, bool isConnected, void Function() showReNameDlg) {
    if (PlatformExt.isMobile) {
      _showBottomDetailSheet(
        device,
        isConnected,
        showReNameDlg,
        Get.context!,
        device.protocol,
      );
    }
  }

  ///显示底部弹窗
  void _showBottomDetailSheet(
    Device device,
    bool isConnected,
    void Function() showReNameDlg,
    BuildContext context,
    TransportProtocol protocol,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      elevation: 100,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: 200,
            constraints: const BoxConstraints(minWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Constants.devTypeIcons[device.type]!.icon,
                          color: isConnected ? Colors.lightBlue : Colors.grey,
                          size: Constants.devTypeIcons[device.type]!.size,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.displayName,
                              style: const TextStyle(fontSize: 25),
                            ),
                            Text(
                              device.address ?? "",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          splashColor: Colors.black12,
                          onTap: showReNameDlg,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                            child: Column(
                              children: [
                                const Icon(Icons.edit_note_rounded),
                                Text(TranslationKey.rename.tr),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            var devInfo = DevInfo.fromDevice(device);
                            if (isConnected) {
                              if (protocol == TransportProtocol.webdav || protocol == TransportProtocol.s3) {
                                storageService.disconnectDevice(devInfo.guid);
                              } else {
                                sktService.disconnectDevice(
                                  devInfo,
                                  true,
                                );
                              }
                            } else {
                              if(protocol.isSocket){
                                sktService.reconnectOnce(device.guid);
                              } else {
                                storageService.connectDevice(devInfo.guid);
                              }
                            }
                            Navigator.pop(context);
                          },
                          splashColor: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                            child: Column(
                              children: [
                                Icon(
                                  isConnected ? Icons.link_off_outlined : Icons.link,
                                ),
                                Text(
                                  isConnected ? TranslationKey.devicePageDisconnect.tr : TranslationKey.devicePageReconnect.tr,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Global.showTipsDialog(
                              context: context,
                              text: TranslationKey.devicePageUnpairedDialogContent.tr,
                              onOk: () async {
                                final devInfo = DevInfo.fromDevice(device);
                                if (isConnected) {
                                  await sktService.onDevForget(devInfo, appConfig.userId);
                                  devInfo.sendData(
                                    MsgType.forgetDev,
                                    {},
                                  );
                                } else {
                                  final confirmResult = await devService.confirmPairingState(
                                    device: device,
                                    localIsPaired: false,
                                    remoteIsPaired: false,
                                    protocol: device.protocol,
                                    manual: true,
                                  );
                                  if (confirmResult.accepted) {
                                    onForget(devInfo, appConfig.userId);
                                  }
                                }
                                Get.back();
                              },
                              showCancel: true,
                            );
                          },
                          splashColor: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                            child: Column(
                              children: [
                                const Icon(Icons.block_flipped),
                                Text(TranslationKey.devicePageUnpairedButtonText.tr),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => Visibility(
                          visible: appConfig.autoSyncMissingData && isConnected,
                          child: Expanded(
                            child: InkWell(
                              onTap: () {
                                Global.showSnackBarSuc(text: TranslationKey.syncingData.tr, context: context);
                                sktService.reqMissingData(device.guid);
                              },
                              splashColor: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5, bottom: 5),
                                child: Column(
                                  children: [
                                    const Icon(Icons.sync_rounded),
                                    Text(TranslationKey.syncData.tr),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  ///取消配对
  void cancelPairing(DevInfo dev) {
    if (!newPairing) return;
    Get.back();
    newPairing = false;
    dev.sendData(MsgType.cancelPairing, {}, false);
  }

  ///请求配对设备
  void _requestPairing(DevInfo dev, BuildContext context) {
    newPairing = true;
    dev.sendData(MsgType.reqPairing, {}, false);
    pairing.value = false;
    pairingFailed.value = false;
    var result = showDialog(
      context: context,
      builder: (context) {
        final TextEditingController pinCtr = TextEditingController();
        bool completedInputPin = false;
        bool showTimeoutText = false;
        const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
        const submittedColor = Color.fromRGBO(114, 178, 238, 1);
        final defaultPinTheme = PinTheme(
          width: 40,
          height: 40,
          textStyle: const TextStyle(
            fontSize: 20,
            color: submittedColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: submittedColor),
            borderRadius: BorderRadius.circular(8),
          ),
        );
        return StatefulBuilder(
          builder: (context, state) {
            pairingState = state;
            onSubmitted() {
              String pin = pinCtr.text;
              dev.sendData(
                MsgType.pairing,
                {"code": CryptoUtil.toMD5(pin)},
                false,
              );
              pairing.value = true;
              showTimeoutText = false;
              pairingFailed.value = false;
              Future.delayed(5.s, () {
                if (pairing.value) {
                  pairing.value = false;
                  showTimeoutText = true;
                  state(() {});
                }
              });
              state(() {});
            }

            return AlertDialog(
              title: Text(TranslationKey.devicePagePairingDialogTitle.tr),
              contentPadding: const EdgeInsets.all(8),
              content: Container(
                height: 90,
                constraints: const BoxConstraints(minWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Pinput(
                      length: 6,
                      controller: pinCtr,
                      autofocus: true,
                      defaultPinTheme: defaultPinTheme,
                      closeKeyboardWhenCompleted: false,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: focusedBorderColor),
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: submittedColor),
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: Colors.redAccent),
                        ),
                        textStyle: defaultPinTheme.textStyle!.copyWith(color: Colors.redAccent),
                      ),
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onChanged: (pin) {
                        completedInputPin = pin.length == 6;
                        state(() {});
                      },
                      onSubmitted: (code) {
                        onSubmitted();
                      },
                    ),
                    (showTimeoutText || pairingFailed.value)
                        ? Text(
                            showTimeoutText ? TranslationKey.devicePagePairingTimeoutText.tr : TranslationKey.devicePagePairingErrorText.tr,
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: Colors.redAccent),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: pairing.value ? null : () => cancelPairing(dev),
                  child: Text(TranslationKey.dialogCancelText.tr),
                ),
                pairing.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: ExcludeSemantics(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: completedInputPin ? onSubmitted : null,
                        child: Text(
                          TranslationKey.devicePagePairingDialogConfirmText.tr,
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
    result.then((value) {
      pairing.value = false;
    });
  }

  ///设置旋转动画
  void setRotationAnimation([bool init = false]) {
    final anim = Tween<double>(
      begin: 0.0,
      end: 1 * (rotationReverse.value ? -1 : 1),
    ).animate(_rotationController);
    if (init) {
      animation = anim.obs;
    } else {
      animation.value = anim;
    }
  }

  ///通知在线设备弹窗
  void _notifyOnlineDevicesWindow() {
    //通知弹窗更新设备列表
    final onlineDevicesWindow = appConfig.onlineDevicesWindow;
    if (onlineDevicesWindow != null) {
      multiWindowChannelService.notify(onlineDevicesWindow.windowId);
    }
  }

  ///添加已配对设备，更新 ui
  void _addPairedDevInPage(Device dev) {
    //配对成功，从连接列表中移除
    var discoverDev = discoverList.firstWhereOrNull((ele) => ele.dev?.guid == dev.guid);
    discoverList.removeWhere((ele) => ele.dev?.guid == dev.guid);
    //添加到已配对列表
    pairedList.removeWhere((ele) => ele.dev?.guid == dev.guid);
    pairedList.add(
      (discoverDev ??
              DeviceCard(
                dev: dev,
                isPaired: false,
                isConnected: true,
                isSelf: false,
                minVersion: null,
                version: null,
                protocol: dev.protocol,
              ))
          .copyWith(
        dev: dev,
        isPaired: true,
        isConnected: true,
        onTap: (device, isConnected, showReNameDlg) {
          if (PlatformExt.isDesktop) {
            _showBottomDetailSheet(
              device,
              isConnected,
              showReNameDlg,
              Get.context!,
              discoverDev?.protocol ?? dev.protocol,
            );
          }
        },
        onLongPress: (device, isConnected, showReNameDlg) {
          if (PlatformExt.isMobile) {
            _showBottomDetailSheet(
              device,
              isConnected,
              showReNameDlg,
              Get.context!,
              discoverDev?.protocol ?? dev.protocol,
            );
          }
        },
      ),
    );
    pairedList.sort((a, b) => a.dev!.displayName.compareTo(b.dev!.displayName));
  }

  //endregion
}
