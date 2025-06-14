import 'package:clipshare/app/utils/log.dart';

enum Module {
  unknown(moduleName: "未知"),
  device(moduleName: "设备管理"),
  tag(moduleName: "标签管理"),
  history(moduleName: "历史记录"),
  rules(moduleName: "规则设置"),
  historyTop(moduleName: "历史记录置顶"),
  historySource(moduleName: "历史记录来源"),
  appInfo(moduleName: "App信息");

  const Module({required this.moduleName});

  final String moduleName;

  static Module getValue(String name) => Module.values.firstWhere(
        (e) => e.moduleName == name,
        orElse: () {
          Log.debug("Module", "key '$name' unknown");
          return Module.unknown;
        },
      );
}
