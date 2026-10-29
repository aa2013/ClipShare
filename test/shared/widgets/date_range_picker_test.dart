import 'package:calendar_date_picker2/calendar_date_picker2.dart' show CalendarDatePicker2, CalendarDatePicker2Type, CalendarDatePicker2WithActionButtonsConfig;
import 'package:clipshare/shared/widgets/dialogs/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// 为实际弹窗入口提供指定尺寸的路由宿主。
Future<BuildContext> pumpHost(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  late BuildContext context;
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (value) {
    context = value;
    return const Scaffold();
  })));
  return context;
}

void main() {
  const sizes = [Size(1000, 600), Size(390, 700), Size(600, 700)];
  for (final size in sizes) {
    testWidgets('日期弹窗在 $size 下不溢出且实时更新选择', (tester) async {
      final context = await pumpHost(tester, size);
      final result = showCalendarDatePicker2Dialog(
        context: context,
        config: CalendarDatePicker2WithActionButtonsConfig(calendarType: CalendarDatePicker2Type.range),
        dialogSize: const Size(325, 400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final calendar = find.byType(CalendarDatePicker2);
      final first = find.descendant(of: calendar, matching: find.text('10')).first;
      final last = find.descendant(of: calendar, matching: find.text('12')).first;
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(last);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Confirm')).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
      expect(await result, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('月份弹窗在 $size 下十二个月可见且选中背景为圆形', (tester) async {
      final context = await pumpHost(tester, size);
      final result = showMonthRangePicker(context: context);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final grid = find.byType(GridView);
      final gridRect = tester.getRect(grid);
      for (var month = 1; month <= 12; month++) {
        final cell = find.descendant(of: grid, matching: find.text(DateFormat.MMM('en').format(DateTime(2026, month))));
        expect(cell.hitTestable(), findsOneWidget);
        expect(gridRect.contains(tester.getCenter(cell)), isTrue);
      }
      await tester.tap(find.text('Dec'));
      await tester.pumpAndSettle();
      final state = tester.state<MonthRangePickerState>(find.byType(MonthRangePicker));
      expect(state.selection!.start.month, 12);
      expect(state.selection!.end, state.selection!.start);
      final button = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Dec'));
      expect(button.style!.shape!.resolve({}), isA<CircleBorder>());
      await tester.tap(find.text('Feb'));
      await tester.pumpAndSettle();
      expect(state.selection!.start.month, 2);
      expect(state.selection!.end.month, 12);
      await tester.tap(find.text('May'));
      await tester.pumpAndSettle();
      expect(state.selection!.start.month, 5);
      expect(state.selection!.end.month, 5);
      await tester.tap(find.text('${DateTime.now().year}'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final years = find.descendant(of: find.byType(GridView), matching: find.byType(Text));
      expect(years.hitTestable(), findsNWidgets(12));
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Cancel'), findsNothing);
      expect(await result, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
