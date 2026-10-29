import 'package:clipshare/core/settings/data_cleanup/data_cleanup_freq.dart';
import 'package:clipshare/features/data_cleanup/enums/week_day.dart';
import 'package:clipshare/shared/utils/cron_util.dart';

/// 构建自动清理的 UnixCron 表达式。
///
/// [frequency] 为 day/week 时由分/时（/星期）字段生成；
/// 为 cron 时返回用户输入 [cronInput]（去除首尾空白）。
/// [minute]/[hour] 为两位字符串，如 "30"、"08"。
String buildCronExpression({
  required DataCleanupFreq frequency,
  required String minute,
  required String hour,
  WeekDay? weekDay,
  required String cronInput,
}) {
  if (frequency == DataCleanupFreq.day) {
    return '$minute $hour * * *';
  }
  if (frequency == DataCleanupFreq.week) {
    return '$minute $hour * * ${weekDay?.value ?? 1}';
  }
  return cronInput.trim();
}

/// 计算表达式的下次执行时间，表达式非法时返回 null。
DateTime? nextExecTimeOf(String cron) {
  return CronUtil.getNextTime(cron);
}
