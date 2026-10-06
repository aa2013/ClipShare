import 'dart:async';
import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/transport_protocol.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

//设备类型图片
final Map<PlatformType, Icon> devTypeIcons = {
  PlatformType.windows: const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.android: const Icon(
    SimpleIcons.android,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.mac: const Icon(
    Icons.laptop_mac_outlined,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.linux: const Icon(
    SimpleIcons.linux,
    color: Colors.grey,
    size: 48,
  ),
  PlatformType.ios: const Icon(
    Icons.apple_outlined,
    color: Colors.grey,
    size: 48,
  ),
};

class DeviceCard extends StatefulWidget {
  final Device? device;
  final void Function(Device device, bool connected)? onTap;
  final void Function(Device device, bool connected)? onLongPress;
  final ValueChanged<Device> onRenameButtonClicked;
  final bool isPaired;
  final bool isConnected;
  final AppVersion? minVersion;
  final AppVersion? targetVersion;
  final AppVersion selfVersion;
  final AppVersion selfMinVersion;
  final TransportProtocol protocol;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onLongPress,
    required this.onRenameButtonClicked,
    required this.isPaired,
    required this.isConnected,
    required this.minVersion,
    required this.targetVersion,
    required this.selfVersion,
    required this.selfMinVersion,
    required this.protocol,
  });

  bool get isVersionCompatible {
    if (minVersion == null || targetVersion == null) {
      return true;
    }
    return minVersion! <= selfVersion && targetVersion! >= selfVersion;
  }

  @override
  State<StatefulWidget> createState() => _DeviceCardState();

  DeviceCard copyWith({
    Device? device,
    void Function(Device device, bool connected)? onTap,
    void Function(Device device, bool connected)? onLongPress,
    ValueChanged<Device>? onRenameButtonClicked,
    bool? isPaired,
    bool? isConnected,
    bool? isSelf,
    AppVersion? minVersion,
    AppVersion? targetVersion,
    AppVersion? selfVersion,
    AppVersion? selfMinVersion,
    TransportProtocol? protocol,
  }) {
    final connected = isConnected ?? this.isConnected;
    return DeviceCard(
      device: device ?? this.device,
      isPaired: isPaired ?? this.isPaired,
      isConnected: connected,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onRenameButtonClicked: onRenameButtonClicked ?? this.onRenameButtonClicked,
      minVersion: !connected ? null : minVersion ?? this.minVersion,
      targetVersion: !connected ? null : targetVersion ?? this.targetVersion,
      selfVersion: selfVersion ?? this.selfVersion,
      selfMinVersion: selfMinVersion ?? this.selfMinVersion,
      protocol: protocol ?? this.protocol,
    );
  }
}

class _DeviceCardState extends State<DeviceCard> {
  bool isEmpty = true;
  Icon emptyIcon = const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  );
  int emptyIconIdx = 0;
  Timer? timer;

  IconData get currentIconData => (devTypeIcons[PlatformType(widget.device!.type)] ?? const Icon(Icons.devices_other_outlined)).icon!;

  bool get showConnectedAccent => !isEmpty && widget.isPaired && widget.isConnected;

  AppVersion get minVersion {
    if (widget.selfMinVersion > widget.minVersion!) {
      return widget.selfMinVersion;
    }
    return widget.minVersion!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = getDeviceAccentColor(context);
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
          if (isEmpty) {
            return;
          }
          widget.onTap?.call(widget.device!, widget.isConnected);
        },
        onLongPress: () {
          if (isEmpty) {
            return;
          }
          widget.onLongPress?.call(widget.device!, widget.isConnected);
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
                        child: buildDeviceIcon(context, accentColor, colorScheme),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      Expanded(
                        child: buildDeviceInfo(colorScheme),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      SizedBox(
                        width: compact ? 46 : 52,
                        child: buildStatusMark(context, colorScheme),
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

  Color getDeviceAccentColor(BuildContext context) {
    if (!showConnectedAccent) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    return Colors.green;
  }

  IconData getStatusIconData() {
    if (isEmpty || !widget.isConnected) {
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

  String getStatusLabel() {
    if (isEmpty || !widget.isConnected) {
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

  Color getDeviceIconBackgroundColor(BuildContext context, ColorScheme colorScheme) {
    if (!showConnectedAccent) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.64);
    }
    return Colors.green.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.14);
  }

  Widget buildDeviceIcon(BuildContext context, Color accentColor, ColorScheme colorScheme) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getDeviceIconBackgroundColor(context, colorScheme),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        isEmpty ? emptyIcon.icon ?? Icons.devices_other_outlined : currentIconData,
        color: accentColor,
        size: 21,
      ),
    );
  }

  Widget buildStatusMark(BuildContext context, ColorScheme colorScheme) {
    if (isEmpty) {
      return const SizedBox.shrink();
    }
    final accentColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          getStatusIconData(),
          color: accentColor,
          size: 22,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            getStatusLabel(),
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

  Widget buildTagChip(String text, ColorScheme colorScheme) {
    final empty = isEmpty && text.trim().isEmpty;
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

  List<Widget> buildTagChips(ColorScheme colorScheme) {
    return [
      buildTagChip(isEmpty ? '    ' : widget.device!.type, colorScheme),
      // if (widget.isSelf) buildTagChip(TranslationKey.selfDeviceName.tr, colorScheme),
      if (!widget.isVersionCompatible)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: () {
                dialogManager.tips(
                  context,
                  text: TranslationKey.notCompatibleDialogText.trParams({
                    'minName': minVersion.name,
                    'minCode': minVersion.code,
                    'selfName': widget.selfVersion.name,
                    'selfCode': widget.selfVersion.code,
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

  Widget buildNameRow() {
    if (isEmpty) {
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
            widget.device!.displayName,
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
                  widget.onRenameButtonClicked(widget.device!);
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

  Widget buildDeviceInfo(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildNameRow(),
        const SizedBox(height: 4),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: buildTagChips(colorScheme),
        ),
      ],
    );
  }

  void setTimer() {
    timer = Timer.periodic(1200.ms, (timer) {
      final key = devTypeIcons.keys.elementAt(emptyIconIdx % devTypeIcons.length);
      emptyIcon = devTypeIcons[key]!;
      emptyIconIdx++;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    isEmpty = widget.device == null;
    if (isEmpty) {
      setTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
