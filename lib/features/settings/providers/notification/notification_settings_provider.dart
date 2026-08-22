import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'notification_settings.dart';

part 'notification_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<NotificationSettings> notificationSettings(Ref ref) async {
  return const NotificationSettings();
}
