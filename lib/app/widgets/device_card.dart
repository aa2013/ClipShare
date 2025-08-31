import 'dart:async';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/dot.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceCard extends StatefulWidget {
  final Device? dev;
  final void Function(Device, bool, void Function())? onTap;
  final void Function(Device, bool, void Function())? onLongPress;
  final bool isPaired;
  final bool isSelf;
  final bool isConnected;
  final AppVersion? minVersion;
  final AppVersion? version;
  final bool isForward;
  final appConfig = Get.find<ConfigService>();

  DeviceCard({
    super.key,
    required this.dev,
    this.onTap,
    this.onLongPress,
    required this.isPaired,
    required this.isConnected,
    required this.isSelf,
    required this.minVersion,
    required this.version,
    this.isForward = false,
  });

  bool get isVersionCompatible => minVersion == null || version == null
      ? true
      : minVersion! <= appConfig.version && version! >= appConfig.minVersion;

  @override
  State<StatefulWidget> createState() {
    return _DeviceCardState();
  }

  DeviceCard copyWith({
    Device? dev,
    void Function(Device, bool, void Function())? onTap,
    void Function(Device, bool, void Function())? onLongPress,
    bool? isPaired,
    bool? isConnected,
    bool? isSelf,
    AppVersion? minVersion,
    AppVersion? version,
    bool? isForward,
  }) {
    isConnected = isConnected ?? this.isConnected;
    return DeviceCard(
      dev: dev ?? this.dev,
      isPaired: isPaired ?? this.isPaired,
      isConnected: isConnected,
      isSelf: isSelf ?? this.isSelf,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      minVersion: !isConnected ? null : minVersion ?? this.minVersion,
      version: !isConnected ? null : version ?? this.version,
      isForward: isForward ?? this.isForward,
    );
  }
}

class _DeviceCardState extends State<DeviceCard> {
  final Color _connColor = Colors.green;
  bool _empty = true;
  Icon _emptyIcon = const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  );
  int _emptyIconIdx = 0;
  Timer? timer;

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();

  Icon get _currIcon => Constants.devTypeIcons[widget.dev!.type]!;

  void _setTimer() {
    timer = Timer.periodic(1200.ms, (timer) {
      String key = Constants.devTypeIcons.keys
          .elementAt(_emptyIconIdx % Constants.devTypeIcons.length);
      _emptyIcon = Constants.devTypeIcons[key]!;
      _emptyIconIdx++;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _empty = widget.dev == null;
    if (_empty) {
      _setTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  ///重命名弹窗
  void _showRenameDialog() {
    var dev = widget.dev!;
    var textController = TextEditingController();
    textController.text = dev.customName ?? "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("重命名设备"),
          content: SizedBox(
            width: 300,
            child: TextField(
              autofocus: true,
              controller: textController,
              decoration: InputDecoration(
                label: Text(TranslationKey.pleaseInput.tr),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(TranslationKey.dialogCancelText.tr),
            ),
            TextButton(
              onPressed: () {
                var name = textController.text;
                devService.addOrUpdate(dev..customName = name).then((res) {
                  if (res) {
                    widget.dev!.customName = name;
                    var opRecord = OperationRecord.fromSimple(
                      Module.device,
                      OpMethod.update,
                      dev.guid,
                    );
                    dbService.opRecordDao.addAndNotify(opRecord);
                    Navigator.pop(context);
                    setState(() {});
                  }
                });
              },
              child: Text(TranslationKey.save.tr),
            ),
          ],
        );
      },
    );
  }

  AppVersion get minVersion => appConfig.minVersion > widget.minVersion!
      ? appConfig.minVersion
      : widget.minVersion!;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: () {
          if (_empty) {
            return;
          }
          widget.onTap
              ?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        onLongPress: () {
          if (_empty) {
            return;
          }
          widget.onLongPress
              ?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _empty ? _emptyIcon : _currIcon,
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _empty
                          ? const RoundedChip(
                              label: Text("                  "),
                            )
                          : Row(
                              children: [
                                Text(
                                  widget.dev!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                widget.isPaired
                                    ? IconButton(
                                        onPressed: () {
                                          _showRenameDialog();
                                        },
                                        icon: const Icon(
                                          Icons.edit_note,
                                        ),
                                        tooltip: TranslationKey.rename.tr,
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          Visibility(
                            visible: !_empty && widget.isPaired,
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: Dot(
                                radius: 6.0,
                                color: widget.isConnected
                                    ? _connColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          RoundedChip(
                            label: Text(_empty ? "    " : widget.dev!.type),
                          ),
                          Visibility(
                            visible: widget.isSelf,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: RoundedChip(
                                label: Text(TranslationKey.selfDeviceName.tr),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: widget.isForward,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: RoundedChip(
                                label: Text(TranslationKey.forward.tr),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !widget.isVersionCompatible,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    onPressed: () => {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: TranslationKey
                                            .notCompatibleDialogText
                                            .trParams({
                                          "minName": minVersion.name,
                                          "minCode": minVersion.code,
                                          "selfName": appConfig.version.name,
                                          "selfCode": appConfig.version.code,
                                        }),
                                      ),
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    TranslationKey.notCompatible.tr,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
