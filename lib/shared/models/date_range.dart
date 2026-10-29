/// 日期/月份范围选择结果
class DateRange {
  /// 起始端点。
  final DateTime start;

  /// 结束端点。
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// 返回替换任一端点后的新范围。
  DateRange copyWith({
    DateTime? start,
    DateTime? end,
  }) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() {
    return 'DateRange(start: $start, end: $end)';
  }
}
