import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:clipshare/app/data/enums/device_paried_filter_status.dart';
import 'package:clipshare/app/data/enums/forward_server_status.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/dialog/add_device_dialog.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/device_card.dart';
import 'package:clipshare/app/widgets/dot.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/loading_dots.dart';
import 'package:clipshare/app/widgets/dialog/network_address_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DevicePage extends GetView<DeviceController> {
  final sktService = Get.find<SocketService>();
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: <Widget>[
            //我的设备列表
            Obx(
              () {
                final filteredPairedList = controller.filteredPairedList;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 12),
                      child: Visibility(
                        visible: controller.pairedList.isNotEmpty,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.devices_rounded),
                                const SizedBox(width: 5),
                                Text(
                                  TranslationKey.devicePageMyDevicesText.name.trParams({
                                    'length': controller.pairedList.length.toString(),
                                  }),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "宋体",
                                  ),
                                ),
                                CupertinoSegmentedControl(
                                  //子标签
                                  children: controller.pairedFilterSegmented,
                                  //当前选中的索引
                                  groupValue: controller.pairedFilter.value,
                                  //点击回调
                                  onValueChanged: (filter) {
                                    controller.pairedFilter.value = filter;
                                  },
                                ),
                              ],
                            ),
                            Obx(
                              () => Offstage(
                                offstage: !appConfig.enableForward,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      child: Dot(
                                        radius: 6.0,
                                        color: controller.forwardStatus.value.color,
                                      ),
                                    ),
                                    Text(TranslationKey.devicePageForwardServerText.tr),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (controller.pairedList.isNotEmpty)
                      Visibility(
                        visible: filteredPairedList.isNotEmpty,
                        replacement: EmptyContent(),
                        child: renderGridView(filteredPairedList),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Obx(
                    () => Icon(
                      Icons.online_prediction_rounded,
                      color: controller.discovering.value ? Colors.blueGrey : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Obx(
                    () => Text(
                      TranslationKey.devicePageDiscoverDevicesText.trParams({
                        'length': controller.discoverList.length.toString(),
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: TranslationKey.devicePageRediscoverTooltip.tr,
                    child: Obx(
                      () => RotationTransition(
                        turns: controller.animation.value,
                        child: IconButton(
                          onPressed: () {
                            if (controller.discovering.value) {
                              controller.rotationReverse.value = !controller.rotationReverse.value;
                              controller.setRotationAnimation();
                              sktService.restartDiscoveryDevices();
                            } else {
                              sktService.startDiscoveryDevices();
                            }
                          },
                          icon: const Icon(
                            Icons.sync,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: TranslationKey.devicePageManuallyTooltip.tr,
                    child: IconButton(
                      onPressed: () {
                        Global.showDialog(context, const AddDeviceDialog());
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.discovering.value,
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
                  ),
                  Expanded(
                    child: Obx(() {
                      if (appConfig.deviceDiscoveryStatus.value == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 15, left: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: LoadingDots(text: Text(appConfig.deviceDiscoveryStatus.value!)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            //设备发现列表，此处不可以用Visibility组件控制渲染，会导致RoundedClip组件背景色失效
            Obx(
              () => ConditionWidget(
                visible: controller.discoverList.isEmpty,
                replacement: renderGridView(controller.discoverList),
                child: DeviceCard(
                  dev: null,
                  isPaired: false,
                  isConnected: false,
                  isSelf: false,
                  minVersion: null,
                  version: null,
                  protocol: TransportProtocol.direct,
                ),
              ),
            ),
            //查看本机IP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    var interfaces = await NetworkInterface.list();
                    for (var itf in interfaces) {
                      // itf.addresses[0].type
                      print("${itf.name} ${itf.addresses.join(',')}");
                    }
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        return NetworkAddressDialog(
                          interfaces: interfaces,
                        );
                      },
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
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

  //region 页面方法

  ///创建设备列表 gridview
  Widget renderGridView(List<DeviceCard> list) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Obx(() {
          const maxWidth = 395;
          final showMore = appConfig.showMoreItemsInRow && !appConfig.isSmallScreen;
          final listLength = list.length;
          final count = showMore && listLength >= 2 ? max(2, constraints.maxWidth ~/ maxWidth) : 1;
          return MasonryGridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: count,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            itemCount: listLength,
            itemBuilder: (context, index) {
              return list[index];
            },
          );
        });
      },
    );
  }

  //endregion
}
