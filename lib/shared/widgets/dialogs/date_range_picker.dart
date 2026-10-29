import 'dart:async';
import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/date_range.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/widgets/base/dialog_actions_bar.dart';
import 'package:clipshare/shared/widgets/layouts/dialog_frame_layout.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 非小屏日期范围弹窗宽度。
const double _dateRangeDialogWidth = 480;

/// 小屏弹窗宽度占屏幕宽度的比例，与日历组件原弹窗的窄屏形态保持一致。
const double _compactWidthRatio = 0.9;

/// 弹窗遮罩色，保留日历组件原有的默认遮罩。
const Color _barrierColor = Colors.black54;

/// 弹窗距屏幕边缘的留白。
const EdgeInsets _compactDialogInset = EdgeInsets.all(16);

/// 按钮条与内容之间的留白。
const EdgeInsets _actionsPadding = EdgeInsets.fromLTRB(16, 8, 16, 12);

/// 标题与内容之间的留白。
const EdgeInsets _titlePadding = EdgeInsets.fromLTRB(16, 12, 16, 0);

/// 弹窗内容与弹窗左右边缘的留白。
const EdgeInsets _contentPadding = EdgeInsets.symmetric(horizontal: 16);

/// 日历选中值转成 [DateRange]：未完整选择两端时返回 null，供确定按钮判断可用态。
DateRange? _toDateRange(List<DateTime?>? values) {
  if (values == null || values.length < 2) {
    return null;
  }
  final start = values[0];
  final end = values[1];
  if (start == null || end == null) {
    return null;
  }
  return DateRange(start: start, end: end);
}

/// 按月归一，统一月份范围的比较口径。
DateTime _normalizeMonth(DateTime date) => DateTime(date.year, date.month);

/// 取一个月与另一个月的先后比较结果，避免直接比较带日期的值。
int _compareMonth(DateTime a, DateTime b) => _normalizeMonth(a).compareTo(_normalizeMonth(b));

/// 使用无按钮的日历实时回传选择，确认与关闭由弹窗外层负责。
Widget _buildCalendar({
  required CalendarDatePicker2WithActionButtonsConfig config,
  required ValueNotifier<DateRange?> selected,
}) {
  final initial = selected.value;
  return CalendarDatePicker2(
    value: initial == null ? const [] : [initial.start, initial.end],
    // 合并年月标题使用可收缩文本，避免窄屏下两个独立标题挤占翻页按钮。
    config: config.copyWith(disableMonthPicker: config.disableMonthPicker ?? true),
    onValueChanged: (values) {
      selected.value = _toDateRange(values);
    },
  );
}

/// 标题 + 正文 + 取消/确定行的小屏卡片，沿用原弹窗的窄屏形态。
class _CompactPickerDialog extends StatelessWidget {
  /// 标题；为空时不渲染标题行。
  final String? title;

  /// 正文内容。
  final Widget content;

  /// 弹窗固定宽度。
  final double width;

  /// 取消回调。
  final VoidCallback onCancel;

  /// 确定回调。
  final VoidCallback onConfirm;

  /// 确定按钮可用态。
  final ValueListenable<bool> confirmEnabled;

  /// 弹窗圆角。
  final BorderRadius borderRadius;

  /// 弹窗背景色；为空时取当前主题表面色。
  final Color? backgroundColor;

  const _CompactPickerDialog({
    required this.content,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmEnabled,
    required this.borderRadius,
    required this.width,
    required this.title,
    this.backgroundColor,
  });

  /// 卡片高度由标题、正文与操作栏共同撑开。
  @override
  Widget build(BuildContext context) {
    final theme = context.currentTheme;
    return Center(
      child: Padding(
        padding: _compactDialogInset,
        child: Material(
          color: backgroundColor ?? theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          elevation: 8,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: _titlePadding,
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                Padding(
                  padding: _contentPadding,
                  child: content,
                ),
                Padding(
                  padding: _actionsPadding,
                  child: DialogActionsBar(
                    actions: DialogActions(
                      cancel: DialogAction(onPressed: onCancel),
                      confirm: DialogAction(enabled: confirmEnabled, onPressed: onConfirm),
                    ),
                    // 先关闭当前弹窗路由，再由按钮回调回传结果。
                    autoDismiss: true,
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

/// 日期范围选择入口。
///
/// 由 [dialogManager] 弹出，不再使用组件库自带的 `showDialog`：非小屏使用
/// [DialogFrameLayout] 边框布局，小屏使用紧凑弹窗，外观与项目其余弹窗一致。
/// [config] 的日历类型应为 [CalendarDatePicker2Type.range]；[value] 传两端已选值可回填。
///
/// 点击确定返回 `[start, end]`，两端未选全时确定不可用；取消、关闭或点击遮罩返回 null。
Future<List<DateTime?>?> showCalendarDatePicker2Dialog({
  required BuildContext context,
  required CalendarDatePicker2WithActionButtonsConfig config,
  required Size dialogSize,
  List<DateTime?> value = const [],
  BorderRadius? borderRadius,
  Color? dialogBackgroundColor,
  Color? barrierColor,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  final completer = Completer<List<DateTime?>?>();
  // 通过按钮条自动关闭弹窗，取消与确定都交由 DialogController 移除路由。
  final selected = ValueNotifier<DateRange?>(_toDateRange(value));
  final confirmEnabled = ValueNotifier<bool>(selected.value != null);
  selected.addListener(() {
    confirmEnabled.value = selected.value != null;
  });
  final calendar = _buildCalendar(config: config, selected: selected);
  final title = TranslationKey.filterByDate.tr;
  final effectiveRadius = borderRadius ?? BorderRadius.circular(10);

  /// 确定：仅在两端都已选中时回传，避免调用方按下标取值时解包失败。
  void confirm() {
    final range = selected.value;
    if (range == null) {
      return;
    }
    completer.complete([range.start, range.end]);
  }

  /// 取消：回传 null。
  void cancel() {
    completer.complete(null);
  }

  DialogController dialog;
  if (context.isCompactScreen) {
    final compactWidth = math.min(
      dialogSize.width,
      context.media.size.width * _compactWidthRatio,
    );
    dialog = dialogManager.open(
      context,
      _CompactPickerDialog(
        title: title,
        content: calendar,
        width: compactWidth,
        onCancel: cancel,
        onConfirm: confirm,
        confirmEnabled: confirmEnabled,
        borderRadius: effectiveRadius,
        backgroundColor: dialogBackgroundColor,
      ),
      dismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? _barrierColor,
    );
  } else {
    dialog = dialogManager.frame(
      context,
      icon: Icons.date_range_outlined,
      title: title,
      width: _dateRangeDialogWidth,
      scrollable: false,
      fitContent: true,
      // 弹窗在按钮点击后自动关闭，关闭时机由 DialogController 控制。
      autoDismiss: true,
      content: calendar,
      actions: DialogActions(
        cancel: DialogAction(onPressed: cancel),
        confirm: DialogAction(enabled: confirmEnabled, onPressed: confirm),
      ),
      dismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor ?? _barrierColor,
    );
  }
  // 弹窗被外部关闭（点遮罩、按返回键、closeAll）时同样回传 null，避免调用方永久等待。
  unawaited(dialog.future.whenComplete(() {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
    selected.dispose();
    confirmEnabled.dispose();
  }));
  return completer.future;
}

/// 月份范围选择器面板。
///
/// 不依赖原组件的 provider 翻页状态：月份与年份网格由本组件按四列排版，
/// 头部提供年份展示与上下翻页，格子尺寸随可用宽度自适应，放进项目弹窗不会出现固定尺寸留白。
/// 点选语义与原组件一致：首次点击为起点，再点一次为终点，两端都有后第三次点击重开区间。
class MonthRangePicker extends StatefulWidget {
  /// 初始选中范围；两端都非空时才回填。
  final DateRange? initialRange;

  /// 可选月份下界。
  final DateTime? firstMonth;

  /// 可选月份上界。
  final DateTime? lastMonth;

  /// 月份选中变化回调，用于驱动调用方的确定按钮可用态。
  final ValueChanged<DateRange>? onChanged;

  const MonthRangePicker({
    super.key,
    this.initialRange,
    this.firstMonth,
    this.lastMonth,
    this.onChanged,
  });

  @override
  State<MonthRangePicker> createState() => MonthRangePickerState();
}

class MonthRangePickerState extends State<MonthRangePicker> {
  /// 月份与年份网格列数。
  static const int _columns = 4;

  /// 年份网格每页年数，与原组件一致。
  static const int _yearsPerPage = 12;

  /// 上下界都缺省时，允许在起始年前后各选多少年。
  static const int _defaultYearSpan = 50;

  /// 格子最小宽高，保证弹窗变窄时仍可点击，选中背景按高度取胶囊圆角。
  static const double _minCellWidth = 48;
  static const double _minCellHeight = 48;

  /// 行高独立于列宽，宽屏下仍完整展示三行。
  static const double _cellHeight = 76;
  static const int _monthsPerYear = 12;

  static const EdgeInsets _gridPadding = EdgeInsets.all(8);
  static const EdgeInsets _headerPadding = EdgeInsets.all(16);
  static const EdgeInsets _yearButtonPadding = EdgeInsets.symmetric(horizontal: 8);
  static const double _headerCornerRadius = 8;
  static const double _headerTextSize = 24;
  static const double _arrowIconSize = 20;
  static const double _arrowButtonSize = 32;
  static const double _headerGap = 8;
  static const double _rangeLightness = 0.7;

  DateTime? _start;

  /// 结束端点；为 null 表示只选了起点，等待第二次点击。
  DateTime? _end;

  /// 当前展示的年份。
  late int _year;

  /// 可选的年份下界与上界。
  late int _firstYear;
  late int _lastYear;

  /// 是否正在选择年份。
  bool _selectingYear = false;

  /// 无初始范围时只定位展示年份，不将当前月隐式计入选择。
  @override
  void initState() {
    super.initState();
    final initial = widget.initialRange;
    final now = _normalizeMonth(DateTime.now());
    final first = widget.firstMonth;
    final start = initial?.start ?? (first != null && now.isBefore(first) ? first : now);
    final last = widget.lastMonth;
    final displayed = last != null && _compareMonth(start, last) > 0 ? last : start;
    _start = initial == null ? null : _normalizeMonth(initial.start);
    _end = initial == null ? null : _normalizeMonth(initial.end);
    _firstYear = first?.year ?? (displayed.year - _defaultYearSpan);
    _lastYear = last?.year ?? (displayed.year + _defaultYearSpan);
    _year = displayed.year;
  }

  /// 单月选择返回相同端点；尚未点选时返回 null。
  DateRange? get selection {
    final start = _start;
    if (start == null) {
      return null;
    }
    return DateRange(start: start, end: _end ?? start);
  }

  /// 月份是否可选：需落在上下界之间。
  bool _isMonthEnabled(DateTime month) {
    final first = widget.firstMonth;
    final last = widget.lastMonth;
    if (first != null && _compareMonth(month, first) < 0) {
      return false;
    }
    if (last != null && _compareMonth(month, last) > 0) {
      return false;
    }
    return true;
  }

  /// 点选一个月：先定起点，再定终点；两端都已选后重开区间，与原组件语义一致。
  void _onMonthTap(DateTime month) {
    final start = _start;
    setState(() {
      if (start == null || _end != null) {
        _start = month;
        _end = null;
      } else if (month.isBefore(start)) {
        _start = month;
        _end = start;
      } else {
        _end = month;
      }
    });
    final range = selection;
    if (range != null) {
      widget.onChanged?.call(range);
    }
  }

  /// 选中年份：年月视图切换回月份视图。
  void _onYearTap(int year) {
    setState(() {
      _year = year;
      _selectingYear = false;
    });
  }

  /// 头部箭头翻页：月份视图按年翻，年份视图按页翻。
  void _shiftPage(int delta) {
    setState(() {
      if (_selectingYear) {
        final pageCount = math.max(1, ((_lastYear - _firstYear) ~/ _yearsPerPage) + 1);
        final currentPage = ((_year - _firstYear) ~/ _yearsPerPage).clamp(0, pageCount - 1);
        final nextPage = (currentPage + delta).clamp(0, pageCount - 1);
        if (nextPage != currentPage) {
          _year = (_firstYear + nextPage * _yearsPerPage).clamp(_firstYear, _lastYear);
        }
      } else {
        final nextYear = _year + delta;
        if (nextYear >= _firstYear && nextYear <= _lastYear) {
          _year = nextYear;
        }
      }
    });
  }

  /// 网格按行高撑开，完整显示当前页。
  @override
  Widget build(BuildContext context) {
    final theme = context.currentTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(theme),
        _selectingYear ? _buildYearGrid(theme) : _buildMonthGrid(theme),
      ],
    );
  }

  /// 头部：当前年份（可点击切换到年份视图）与翻页箭头。
  Widget _buildHeader(ThemeData theme) {
    final locale = Localizations.localeOf(context).toString();
    final start = _start;
    final end = _end;
    final rangeText = start == null ? '' : DateFormat.yMMM(locale).format(start)
        + (end == null ? '' : ' - ${DateFormat.yMMM(locale).format(end)}');
    final pageStart = _firstYear + ((_year - _firstYear) ~/ _yearsPerPage) * _yearsPerPage;
    final pageLabel = _selectingYear
        ? '$pageStart-${math.min(pageStart + _yearsPerPage - 1, _lastYear)}'
        : DateFormat.y(locale).format(DateTime(_year));
    return Container(
      padding: _headerPadding,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(_headerCornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rangeText, style: theme.primaryTextTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _selectingYear = !_selectingYear),
                    style: TextButton.styleFrom(padding: _yearButtonPadding),
                    child: Text(
                      pageLabel,
                      style: theme.primaryTextTheme.headlineSmall?.copyWith(
                        fontSize: _headerTextSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _headerGap),
              _buildArrow(Icons.keyboard_arrow_up, -1),
              _buildArrow(Icons.keyboard_arrow_down, 1),
            ],
          ),
        ],
      ),
    );
  }

  /// 头部翻页箭头。
  Widget _buildArrow(IconData icon, int delta) {
    return IconButton(
      color: Theme.of(context).primaryIconTheme.color,
      iconSize: _arrowIconSize,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: _arrowButtonSize, height: _arrowButtonSize),
      onPressed: () => _shiftPage(delta),
      icon: Icon(icon),
    );
  }

  /// 月份网格：十二个月固定四列三行，越界月份置灰不可点。
  Widget _buildMonthGrid(ThemeData theme) {
    final selected = selection;
    return GridView.count(
      padding: _gridPadding,
      crossAxisCount: _columns,
      mainAxisExtent: _cellHeight,
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_monthsPerYear, (index) {
        final date = DateTime(_year, index + 1);
        final enabled = _isMonthEnabled(date);
        final isStart = date == _start;
        final isEnd = date == _end;
        final inRange =
            selected != null && date.isAfter(selected.start) && date.isBefore(selected.end);
        return _buildCell(
          theme: theme,
          label: DateFormat.MMM(Localizations.localeOf(context).toString()).format(date),
          enabled: enabled,
          selected: isStart || isEnd,
          inRange: inRange,
          onTap: enabled ? () => _onMonthTap(date) : null,
        );
      }),
    );
  }

  /// 年份网格：每页十二个年份，点击后回到月份视图。
  Widget _buildYearGrid(ThemeData theme) {
    final pageStart = _firstYear + ((_year - _firstYear) ~/ _yearsPerPage) * _yearsPerPage;
    return GridView.count(
      padding: _gridPadding,
      crossAxisCount: _columns,
      mainAxisExtent: _cellHeight,
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_yearsPerPage, (index) {
        final year = pageStart + index;
        final enabled = year >= _firstYear && year <= _lastYear;
        return _buildCell(
          theme: theme,
          label: '$year',
          enabled: enabled,
          selected: year == _year,
          onTap: enabled ? () => _onYearTap(year) : null,
        );
      }),
    );
  }

  /// 与原月份组件一致：端点圆形高亮，区间内部使用浅色背景。
  Widget _buildCell({
    required ThemeData theme,
    required String label,
    required bool enabled,
    required bool selected,
    required VoidCallback? onTap,
    bool inRange = false,
  }) {
    final background = selected ? theme.colorScheme.secondary
        : inRange ? HSLColor.fromColor(theme.colorScheme.secondary).withLightness(_rangeLightness).toColor() : null;
    return Center(
      child: SizedBox(
        width: _minCellWidth,
        height: _minCellHeight,
        child: TextButton(
          onPressed: enabled ? onTap : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            backgroundColor: background,
            foregroundColor: selected || inRange ? theme.colorScheme.onSecondary : null,
            textStyle: theme.textTheme.labelLarge,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// 月份范围选择入口。
///
/// 由 [dialogManager] 弹出，弹窗外壳、取消/确定与项目其余弹窗一致。
/// 点击确定返回所选月份起止两端（两端都归一到当月 1 号），只选了一个月时两端为同一月；
/// 取消、关闭或点击遮罩返回 null。
Future<List<DateTime>?> showMonthRangePicker({
  required BuildContext context,
  DateRange? initialRange,
  DateTime? firstMonth,
  DateTime? lastMonth,
  String? title,
}) {
  final completer = Completer<List<DateTime>?>();
  final pickerKey = GlobalKey<MonthRangePickerState>();
  final confirmEnabled = ValueNotifier<bool>(initialRange != null);
  final effectiveTitle = title ?? TranslationKey.statisticsPageFilterRangeText.tr;

  /// 回传结果；两端相等时也返回两个值，调用方按下标取用不会越界。
  void confirm() {
    final range = pickerKey.currentState?.selection;
    if (range == null) {
      return;
    }
    completer.complete([range.start, range.end]);
  }

  /// 取消：回传 null。
  void cancel() {
    completer.complete(null);
  }

  final picker = MonthRangePicker(
    key: pickerKey,
    initialRange: initialRange,
    firstMonth: firstMonth,
    lastMonth: lastMonth,
    onChanged: (range) => confirmEnabled.value = true,
  );

  DialogController dialog;
  if (context.isCompactScreen) {
    dialog = dialogManager.open(
      context,
      _CompactPickerDialog(
        title: effectiveTitle,
        content: picker,
        width: context.media.size.width * _compactWidthRatio,
        onCancel: cancel,
        onConfirm: confirm,
        confirmEnabled: confirmEnabled,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  } else {
    dialog = dialogManager.frame(
      context,
      icon: Icons.date_range_outlined,
      title: effectiveTitle,
      width: _dateRangeDialogWidth,
      scrollable: false,
      fitContent: true,
      autoDismiss: true,
      content: picker,
      actions: DialogActions(
        cancel: DialogAction(onPressed: cancel),
        confirm: DialogAction(enabled: confirmEnabled, onPressed: confirm),
      ),
    );
  }
  // 弹窗被外部关闭（点遮罩、按返回键、closeAll）时同样回传 null，避免调用方永久等待。
  unawaited(dialog.future.whenComplete(() {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
    confirmEnabled.dispose();
  }));
  return completer.future;
}
