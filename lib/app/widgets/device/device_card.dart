import 'dart:async';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

class DeviceCard extends StatefulWidget {
  final Device? dev;
  final void Function(Device, bool, void Function())? onTap;
  final void Function(Device, bool, void Function())? onLongPress;
  final bool isPaired;
  final bool isSelf;
  final bool isConnected;
  final AppVersion? minVersion;
  final AppVersion? version;
  final TransportProtocol protocol;
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
    required this.protocol,
  });

  bool get isVersionCompatible => minVersion == null || version == null ? true : minVersion! <= appConfig.version && version! >= appConfig.minVersion;

  @override
  State<StatefulWidget> createState() => _DeviceCardState();

  DeviceCard copyWith({
    Device? dev,
    void Function(Device, bool, void Function())? onTap,
    void Function(Device, bool, void Function())? onLongPress,
    bool? isPaired,
    bool? isConnected,
    bool? isSelf,
    AppVersion? minVersion,
    AppVersion? version,
    TransportProtocol? protocol,
  }) {
    final connected = isConnected ?? this.isConnected;
    return DeviceCard(
      dev: dev ?? this.dev,
      isPaired: isPaired ?? this.isPaired,
      isConnected: connected,
      isSelf: isSelf ?? this.isSelf,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      minVersion: !connected ? null : minVersion ?? this.minVersion,
      version: !connected ? null : version ?? this.version,
      protocol: protocol ?? this.protocol,
    );
  }
}

class _DeviceCardState extends State<DeviceCard> {
  bool _empty = true;
  Icon _emptyIcon = const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  );
  int _emptyIconIdx = 0;
  Timer? _timer;

  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();

  IconData get _currIconData => (Constants.devTypeIcons[widget.dev!.type] ?? const Icon(Icons.devices_other_outlined)).icon!;

  bool get _showConnectedAccent => !_empty && widget.isPaired && widget.isConnected;

  Color _deviceAccentColor(BuildContext context) {
    if (!_showConnectedAccent) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    return Colors.green;
  }

  IconData _statusIconData() {
    if (_empty || !widget.isConnected) {
      return Icons.cloud_off_outlined;
    }
    switch (widget.protocol) {
      case TransportProtocol.server:
        return Icons.flash_on_rounded;
      case TransportProtocol.webdav:
        return Icons.cloud_queue_rounded;
      case TransportProtocol.s3:
        return Icons.cloud_done_outlined;
      case TransportProtocol.direct:
        return Icons.router_outlined;
    }
  }

  String _statusLabel() {
    if (_empty || !widget.isConnected) {
      return TranslationKey.disconnected.tr;
    }
    switch (widget.protocol) {
      case TransportProtocol.server:
        return TranslationKey.forward.tr;
      case TransportProtocol.webdav:
        return TransportProtocol.webdav.name.toUpperCase();
      case TransportProtocol.s3:
        return TransportProtocol.s3.name.toUpperCase();
      case TransportProtocol.direct:
        return TranslationKey.directConnect.tr;
    }
  }

  Color _deviceIconBackgroundColor(BuildContext context, ColorScheme colorScheme) {
    if (!_showConnectedAccent) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.64);
    }
    return Colors.green.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.14);
  }

  Widget _buildDeviceIcon(BuildContext context, Color accentColor, ColorScheme colorScheme) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _deviceIconBackgroundColor(context, colorScheme),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        _empty ? _emptyIcon.icon ?? Icons.devices_other_outlined : _currIconData,
        color: accentColor,
        size: 21,
      ),
    );
  }

  Widget _buildStatusMark(BuildContext context, ColorScheme colorScheme) {
    if (_empty) {
      return const SizedBox.shrink();
    }
    final accentColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          _statusIconData(),
          color: accentColor,
          size: 22,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _statusLabel(),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String text, ColorScheme colorScheme) {
    final empty = _empty && text.trim().isEmpty;
    if (empty) {
      return Container(
        width: 34,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            height: 1,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTagChips(ColorScheme colorScheme) {
    return [
      _buildTagChip(_empty ? "    " : widget.dev!.type, colorScheme),
      if (widget.isSelf) _buildTagChip(TranslationKey.selfDeviceName.tr, colorScheme),
      if (!widget.isVersionCompatible)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: () {
                Global.showTipsDialog(
                  context: context,
                  text: TranslationKey.notCompatibleDialogText.trParams({
                    "minName": minVersion.name,
                    "minCode": minVersion.code,
                    "selfName": appConfig.version.name,
                    "selfCode": appConfig.version.code,
                  }),
                );
              },
              child: const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 18,
              ),
            ),
            Text(
              TranslationKey.notCompatible.tr,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
              ),
            ),
          ],
        ),
    ];
  }

  Widget _buildNameRow() {
    if (_empty) {
      return Container(
        width: 132,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.dev!.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 5),
        widget.isPaired
            ? IconButton(
                onPressed: () {
                  _showRenameDialog();
                },
                icon: const Icon(
                  Icons.edit_note,
                  size: 18,
                ),
                tooltip: TranslationKey.rename.tr,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                padding: EdgeInsets.zero,
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildDeviceInfo(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameRow(),
        const SizedBox(height: 4),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _buildTagChips(colorScheme),
        ),
      ],
    );
  }

  void _setTimer() {
    _timer = Timer.periodic(1200.ms, (timer) {
      final key = Constants.devTypeIcons.keys.elementAt(_emptyIconIdx % Constants.devTypeIcons.length);
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
    _timer?.cancel();
    super.dispose();
  }

  ///重命名弹窗
  void _showRenameDialog() {
    final dev = widget.dev!;
    final textController = TextEditingController(text: dev.customName ?? "");
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                final name = textController.text;
                final updatedDev = dev.copyWith(customName: Value(name));
                final res = await devService.addOrUpdate(updatedDev);
                if (!res) {
                  return;
                }
                final opRecord = newOperationRecord(
                  Module.device,
                  OpMethod.update,
                  dev.guid,
                );
                dbService.opRecordDao.addAndNotify(opRecord);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                setState(() {});
              },
              child: Text(TranslationKey.save.tr),
            ),
          ],
        );
      },
    );
  }

  AppVersion get minVersion => appConfig.minVersion > widget.minVersion! ? appConfig.minVersion : widget.minVersion!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = _deviceAccentColor(context);
    final cardColor = theme.cardTheme.color ?? colorScheme.surface;
    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: () {
          if (_empty) {
            return;
          }
          widget.onTap?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        onLongPress: () {
          if (_empty) {
            return;
          }
          widget.onLongPress?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Padding(
              padding: EdgeInsets.fromLTRB(compact ? 14 : 16, 14, compact ? 14 : 16, 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildDeviceIcon(context, accentColor, colorScheme),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      Expanded(
                        child: _buildDeviceInfo(colorScheme),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      SizedBox(
                        width: compact ? 46 : 52,
                        child: _buildStatusMark(context, colorScheme),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
