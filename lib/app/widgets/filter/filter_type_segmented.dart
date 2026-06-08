import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/widgets/base/tiny_segmented_control.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final selectedBackgroundColor = isDarkMode ? theme.colorScheme.primary.withValues(alpha: 0.42) : const Color(0xFFDCEAF5);
    final selectedColor = isDarkMode ? theme.colorScheme.onSurface : const Color(0xFF2F5F7D);
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: isDarkMode ? 0.72 : 0.64);
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
        selectedBackgroundColor: selectedBackgroundColor,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
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
