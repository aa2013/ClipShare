import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

/// 设备平台对应的图标
final Map<PlatformType, IconData> devicePlatformIconData = {
  PlatformType.windows: Icons.laptop_windows_outlined,
  PlatformType.android: SimpleIcons.android,
  PlatformType.mac: Icons.laptop_mac_outlined,
  PlatformType.linux: SimpleIcons.linux,
  PlatformType.ios: Icons.apple_outlined,
};

/// 统一的设备平台图标
///
/// 已连接时图标为绿色高亮，未连接时为中性灰
class DevicePlatformIcon extends StatelessWidget {
  /// 默认容器边长。
  static const double _defaultSize = 38;

  /// 默认图标边长。
  static const double _defaultIconSize = 21;

  /// 默认圆角半径。
  static const double _defaultRadius = 11;

  /// 容器边长；图标与圆角按 DeviceCard 的比例等比缩放。
  final double size;

  /// 设备平台，用于匹配对应图标。
  final PlatformType? platform;

  /// 显式指定的图标，用于空卡片轮播等无法确定平台的场景。
  final IconData? iconData;

  /// 是否已连接，决定绿色高亮或灰色中性样式。
  final bool isConnected;

  const DevicePlatformIcon({
    super.key,
    this.platform,
    this.iconData,
    required this.isConnected,
    this.size = _defaultSize,
  });

  /// 解析展示图标：优先显式图标，其次按平台匹配，最后回退到通用设备图标。
  IconData get _resolvedIcon => iconData ?? devicePlatformIconData[platform] ?? Icons.devices_other_outlined;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isConnected ? Colors.green : colorScheme.onSurfaceVariant;
    final backgroundColor = isConnected
        ? Colors.green.withValues(alpha: isDark ? 0.20 : 0.14)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.64);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * _defaultRadius / _defaultSize),
      ),
      child: Icon(
        _resolvedIcon,
        color: foregroundColor,
        size: size * _defaultIconSize / _defaultSize,
      ),
    );
  }
}
