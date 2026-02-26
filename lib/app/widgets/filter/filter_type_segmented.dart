import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterTypeSegmented extends StatelessWidget {
  static final _filterTypes = List<HistoryContentType>.unmodifiable([
    HistoryContentType.all,
    HistoryContentType.text,
    HistoryContentType.image,
    HistoryContentType.file,
    HistoryContentType.sms,
    HistoryContentType.notification,
  ]);
  final ValueChanged<HistoryContentType> onSelected;

  const FilterTypeSegmented({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Get.theme.brightness == Brightness.dark;
    return TinySegmentedControl(
      options: _filterTypes.map((e) => Text(e.label)).toList(),
      backgroundColor: Colors.transparent,
      selectedBackgroundColor: isDarkMode ? Colors.blueGrey : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      onSelected: (int index) {
        final type = _filterTypes[index];
        onSelected(type);
      },
    );
  }
}
