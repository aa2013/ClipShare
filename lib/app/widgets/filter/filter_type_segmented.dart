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
  final HistoryContentType selectedType;

  const FilterTypeSegmented({
    super.key,
    required this.onSelected,
    this.selectedType = HistoryContentType.all,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Get.theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: TinySegmentedControl(
        options: _filterTypes
            .map(
              (e) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(e.label),
              ),
            )
            .toList(),
        backgroundColor: Colors.transparent,
        selectedBackgroundColor: isDarkMode ? Colors.blueGrey : const Color(0xff62baf8),
        selectedColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        selectedIndex: _filterTypes.indexOf(selectedType),
        onSelected: (int index) {
          final type = _filterTypes[index];
          onSelected(type);
        },
      ),
    );
  }
}
