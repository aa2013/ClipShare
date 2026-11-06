import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/features/settings/pages/level2/settings_clipboard_page.dart';
import 'package:clipshare/features/settings/widgets/card/setting_card.dart';
import 'package:clipshare/l10n/gen/app_localizations_en.dart';
import 'package:clipshare/l10n/l10n_bridge.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _legacySourceKey = 'sourceRecordViaDumpsys';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() async {
    L10nBridge.bind(AppLocalizationsEn());
    database = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDbProvider.overrideWith((ref) async => database),
    ]);
    await container.read(appDbProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('旧来源检测配置不影响现有配置加载', () async {
    await database.configDao.add(const Config(key: _legacySourceKey, value: 'true', uid: 0));
    await database.configDao.addOrUpdate(.sourceRecord, 'true');
    final settings = await container.read(clipboardSettingsProvider.future);
    expect(settings.sourceRecord, isTrue);
    expect(settings.stopListeningOnScreenClosed, isFalse);
    expect(await database.configDao.getConfig(_legacySourceKey), 'true');
  });

  testWidgets('设置条目与搜索 key 不再包含 dumpsys', (tester) async {
    await tester.runAsync(() => container.read(clipboardSettingsProvider.future));
    late List<SettingCard> cards;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Consumer(builder: (context, ref, child) {
        // 直接检查完整条目集合，包含被当前平台隐藏的设置。
        cards = const SettingsClipboardPage().buildSettingEntries(context, ref).cast<SettingCard>();
        return const SizedBox();
      })),
    ));
    expect(cards, hasLength(5));
    final keys = cards.expand((card) => card.searchKeys).toList();
    expect(keys, contains(TranslationKey.clipboardSettingsSourceRecordTitle));
    expect(keys.any((key) => key.name.toLowerCase().contains('dumpsys')), isFalse);
  });
}
