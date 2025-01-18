import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/device_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DeviceController extends GetxController
    with GetSingleTickerProviderStateMixin
    implements
        DevAliveListener,
        SyncListener,
        DiscoverListener,
        ForwardStatusListener {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();

  //region 属性
  final String tag = "DevicesPage";
  final discoverList = List<DeviceCard>.empty(growable: true).obs;
  final pairedList = List<DeviceCard>.empty(growable: true).obs;
  late StateSetter pairingState;
  final pairingFailed = false.obs;
  final pairing = false.obs;
  bool newPairing = false;
  final discovering = true.obs;
  final forwardConnected = false.obs;
  late AnimationController _rotationController;
  final rotationReverse = false.obs;
  late Rx<Animation<double>> animation;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();

    sktService.addDevAliveListener(this);
    sktService.addDiscoverListener(this);
    sktService.addForwardStatusListener(this);
    sktService.addSyncListener(Module.device, this);
    // 旋转动画
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
            onTap: (device, isConnected, showReNameDlg) {
              if (PlatformExt.isDesktop) {
                _showBottomDetailSheet(
                  device,
                  isConnected,
                  showReNameDlg,
                  Get.context!,
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
                );
              }
            },
            isConnected: false,
            isSelf: false,
            minVersion: null,
            version: null,
            isForward: false,
          ),
        );
      }
    });
  }

  @override
  void onClose() {
    sktService.removeDevAliveListener(this);
    sktService.removeDiscoverListener(this);
    sktService.removeForwardStatusListener(this);
    sktService.removeSyncListener(Module.device, this);
    _rotationController.dispose();
    super.onClose();
  }

  //endregion

  //region 监听与同步
  @override
  Future ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    Device dev = Device.fromJson(json);
    Future f = Future(() => null);
    if (dev.guid != appConfig.devInfo.guid) {
      switch (opRecord.method) {
        case OpMethod.add:
          f = dbService.deviceDao.add(dev);
          break;
        case OpMethod.delete:
          dbService.deviceDao.remove(dev.guid, appConfig.userId);
          break;
        case OpMethod.update:
          f = dbService.deviceDao.updateDevice(dev);
          break;
        default:
          return Future.value();
      }
    }
    //发送同步确认
    return f.then(
      (v) => sktService.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.device.moduleName},
      ),
    );
  }

  @override
  void onConnected(
    DevInfo info,
    AppVersion minVersion,
    AppVersion version,
    bool isForward,
  ) async {
    var dev = await Device.fromDevInfo(info);
    for (var i = 0; i < pairedList.length; i++) {
      var paired = pairedList[i];
      if (paired.dev == dev) {
        //修改widget状态
        paired.dev!.address = dev!.address;
        pairedList[i] = paired.copyWith(
          isConnected: true,
          dev: paired.dev,
          minVersion: minVersion,
          version: version,
          isForward: isForward,
        );
        _notifyOnlineDevicesWindow();
        //是已配对的设备，请求所有缺失数据
        // sktService.sendData(null, MsgType.reqMissingData, {});
        return;
      }
    }
    var hasSame = discoverList.firstWhereOrNull(
          (element) => element.dev?.guid == info.guid,
        ) !=
        null;
    if (hasSame) {
      return;
    }
    discoverList.add(
      DeviceCard(
        dev: Device(
          guid: info.guid,
          devName: info.name,
          uid: 0,
          type: info.type,
        ),
        onTap: (device, isConnected, showReNameDlg) =>
            _requestPairing(info, Get.context!),
        minVersion: minVersion,
        version: version,
        isPaired: false,
        isConnected: true,
        isSelf: false,
        isForward: isForward,
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
          isForward: false,
        );
      }
    }
    _notifyOnlineDevicesWindow();
  }

  @override
  void onDiscoverStart() {
    _rotationController.repeat();
    discovering.value = true;
    Log.debug(tag, "onDiscoverStart");
  }

  @override
  void onDiscoverFinished() {
    discovering.value = false;
    Log.debug(tag, "onDiscoverFinished");
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
      // 已经连接，minVersion必定不空
      onConnected(
        dev,
        forgetDev!.minVersion!,
        forgetDev.version!,
        forgetDev.isForward,
      );
    }
    _notifyOnlineDevicesWindow();
  }

  @override
  void onForwardServerConnected() {
    forwardConnected.value = true;
  }

  @override
  void onForwardServerDisconnected() {
    forwardConnected.value = false;
  }

  @override
  void onPaired(DevInfo dev, int uid, bool result, String? address) async {
    if (!result) {
      Log.debug(tag, "_pairingFailed $pairingFailed");
      pairingFailed.value = true;
      pairing.value = false;
      pairingState(() {});
      return;
    }
    //关闭配对弹窗
    Get.back();
    newPairing = false;
    var newDev = Device(
      guid: dev.guid,
      devName: dev.name,
      uid: uid,
      type: dev.type,
      isPaired: true,
      address: address,
    );
    var dbDev = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    if (dbDev != null) {
      //之前配对过，只是取消配对了
      dbDev.isPaired = true;
      devService.addOrUpdate(dbDev).then((res) {
        if (res) {
          _addPairedDevInPage(dbDev);
          //已配对，请求所有缺失数据
          sktService.reqMissingData();
          return;
        }
        Global.showSnackBarErr(
            context: Get.context!,
            text: TranslationKey.deviceAdditionFailedDialogText.tr);
      });
    } else {
      //新设备
      devService.addOrUpdate(newDev).then((res) {
        if (!res) {
          Log.debug(tag, "Device information addition failed");
          Global.showSnackBarErr(
              context: Get.context!,
              text: TranslationKey.deviceAdditionFailedDialogText.tr);
          return;
        }
        _addPairedDevInPage(newDev);
        //已配对，请求所有缺失数据
        sktService.reqMissingData();
      });
    }
  }

  @override
  void onCancelPairing(DevInfo dev) {
    if (!newPairing) return;
    newPairing = false;
    Get.back();
  }

//endregion

//region 页面方法

  ///显示底部弹窗
  void _showBottomDetailSheet(
    Device device,
    bool isConnected,
    void Function() showReNameDlg,
    BuildContext context, [
    bool isForward = false,
  ]) {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      elevation: 100,
      builder: (BuildContext context) {
        return Container(
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
                            device.name,
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
                            sktService.disconnectDevice(
                              devInfo,
                              true,
                            );
                          } else {
                            var address = device.address;
                            var [ip, port] = address!.split(":");
                            final forwardHost = appConfig.forwardServer?.host;
                            if (isForward || ip == forwardHost) {
                              sktService.manualConnectByForward(device.guid);
                            } else {
                              sktService.manualConnect(ip, port: port.toInt());
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
                                isConnected
                                    ? Icons.link_off_outlined
                                    : Icons.link,
                              ),
                              Text(
                                isConnected
                                    ? TranslationKey.devicePageDisconnect.tr
                                    : TranslationKey.devicePageReconnect.tr,
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
                            text: TranslationKey.devicePageUnpairedDialogAck.tr,
                            onOk: () {
                              if (isConnected) {
                                var devInfo = DevInfo.fromDevice(device);
                                sktService.onDevForget(
                                  devInfo,
                                  appConfig.userId,
                                );
                                sktService.sendData(
                                  devInfo,
                                  MsgType.forgetDev,
                                  {},
                                );
                              }
                              //更新配对状态为未配对
                              device.isPaired = false;
                              dbService.deviceDao
                                  .updateDevice(device)
                                  .then((cnt) {
                                if (cnt <= 0) return;
                                onForget(
                                  DevInfo.fromDevice(device),
                                  appConfig.userId,
                                );
                              });
                              Navigator.pop(context);
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
                              Text(TranslationKey
                                  .devicePageUnpairedButtonText.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    sktService.sendData(dev, MsgType.cancelPairing, {});
  }

  ///请求配对设备
  void _requestPairing(DevInfo dev, BuildContext context) {
    newPairing = true;
    sktService.sendData(dev, MsgType.reqPairing, {});
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
              sktService.sendData(
                dev,
                MsgType.pairing,
                {"code": CryptoUtil.toMD5(pin)},
              );
              pairing.value = true;
              showTimeoutText = false;
              pairingFailed.value = false;
              Future.delayed(const Duration(seconds: 5), () {
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
                        textStyle: defaultPinTheme.textStyle!
                            .copyWith(color: Colors.redAccent),
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
                            showTimeoutText
                                ? TranslationKey.devicePagePairingTimeoutText.tr
                                : TranslationKey.devicePagePairingErrorText.tr,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
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

  ///获取兼容版本的在线设备列表
  List<Device> getCompatibleOnlineDevices() {
    List<Device> res = List.empty(growable: true);
    for (var dev in pairedList) {
      if (dev.isConnected && dev.isVersionCompatible) {
        res.add(dev.dev!);
      }
    }
    return res;
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
    var discoverDev =
        discoverList.firstWhere((ele) => ele.dev?.guid == dev.guid);
    discoverList.removeWhere((ele) => ele.dev?.guid == dev.guid);
    //添加到已配对列表
    pairedList.add(
      discoverDev.copyWith(
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
              discoverDev.isForward,
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
              discoverDev.isForward,
            );
          }
        },
      ),
    );
  }
//endregion
}
