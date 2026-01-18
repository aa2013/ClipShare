enum RuleTrigger {
  onCopy,
  onNotification,
  onSms;

  String get tr {
    switch (this) {
      case RuleTrigger.onCopy:
        return "复制后";
      case RuleTrigger.onNotification:
        return "新通知";
      case RuleTrigger.onSms:
        return "新短信";
    }
  }
}
