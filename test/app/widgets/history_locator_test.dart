import 'package:clipshare/app/widgets/history_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reveals a distant record without fetching intervening pages', (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(MaterialApp(home: HistoryLocator(
      id: 500, columns: 2,
      load: (_, offset) async {
        if (offset == null) return {'idx': 9500, 'total': 10000, 'duration': 600};
        offsets.add(offset);
        return {'names': <String,String>{}, 'rows': List.generate(32,(i) => {
          'id':10000-offset-i,'uid':1,'top':0,'sync':0,'size':1,'type':'Text',
          'time':'2026-01-01','content':'hello','devId':'test',
        })};
      },
      card: (clip, _) => Text('record ${clip.data.id}'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('record 500').hitTestable(), findsOneWidget);
    expect(offsets.every((offset) => (offset - 9500).abs() < 64), isTrue);
  });
}
