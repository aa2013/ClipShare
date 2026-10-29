import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/features/device/widgets/device_platform_icon.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';

/// 在线设备多选列表：展示在线且已配对的设备，点击切换选中态
class DeviceSelector extends StatelessWidget {
  final List<Device> devices;
  final Set<String> selectedIds;
  final ValueChanged<Device> onToggle;

  const DeviceSelector({
    super.key,
    required this.devices,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: devices.isEmpty ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, bottom: 5),
          child: Row(
            children: [
              const Icon(
                Icons.devices_outlined,
              ),
              const SizedBox(width: 5),
              Text(
                TranslationKey.onlineDevices.tr,
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: devices.isNotEmpty,
            replacement: Center(
              child: EmptyContent(
                description: TranslationKey.noOnlineDevices.tr,
              ),
            ),
            child: ListView.builder(
              itemCount: devices.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (ctx, idx) {
                final dev = devices[idx];
                final selected = selectedIds.contains(dev.guid);
                return InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () => onToggle(dev),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        //毛玻璃背景上未选中也需要边框界定
                        color: selected ? Colors.blue : Colors.blueGrey.withValues(alpha: 0.35),
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        DevicePlatformIcon(
                          platform: PlatformType(dev.type),
                          isConnected: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dev.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
