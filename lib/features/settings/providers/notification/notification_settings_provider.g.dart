// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationSettings)
final notificationSettingsProvider = NotificationSettingsProvider._();

final class NotificationSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationSettings>,
          NotificationSettings,
          FutureOr<NotificationSettings>
        >
    with
        $FutureModifier<NotificationSettings>,
        $FutureProvider<NotificationSettings> {
  NotificationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsHash();

  @$internal
  @override
  $FutureProviderElement<NotificationSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationSettings> create(Ref ref) {
    return notificationSettings(ref);
  }
}

String _$notificationSettingsHash() =>
    r'3ea05621b82e30fc7757321f30f7ef78da0b52d4';
