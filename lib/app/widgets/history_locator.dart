import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'filter/history_filter.dart';
import '../services/config_service.dart';
import '../services/db_service.dart';
import '../services/device_service.dart';
import '../data/models/clip_data.dart';
import '../data/repository/entity/tables/history.dart';

/// An indexed viewport of the unfiltered history. Only visible pages need
/// their clipboard contents materialized, even when the target is years old.
class HistoryLocator extends StatefulWidget {
  const HistoryLocator({
    super.key,
    required this.id,
    required this.load,
    required this.card,
    this.columns = 1,
  });
  final int id, columns;
  final Future<Map<String, dynamic>> Function(int id, int? offset) load;
  final Widget Function(ClipData, String) card;
  static const pageSize = 32;

  static void reveal(
    HistoryFilterController filter,
    VoidCallback refresh,
    VoidCallback select,
  ) {
    filter.focusNode.unfocus();
    filter.resetFilter();
    refresh();
    select();
  }

  static Future<Map<String, dynamic>> query(int id, int? offset) async {
    final cfg = Get.find<ConfigService>();
    final db = Get.find<DbService>().dbExecutor;
    if (offset == null) {
      final rows = await db.rawQuery(
        '''SELECT count(*) AS total,
        count(CASE WHEN (top,id) > ((SELECT top FROM History WHERE uid=? AND id=?),?) THEN 1 END) AS idx
        FROM History WHERE uid=?''',
        [cfg.userId, id, id, cfg.userId],
      );
      return {...rows.single, 'duration': cfg.historyHighlightMs};
    }
    final rows = await db.rawQuery(
      'SELECT h.* FROM (SELECT id,top FROM History WHERE uid=? ORDER BY top DESC,id DESC LIMIT ? OFFSET ?) p JOIN History h ON h.id=p.id ORDER BY p.top DESC,p.id DESC',
      [cfg.userId, pageSize, offset],
    );
    final names = Get.find<DeviceService>().toIdNameMap();
    names[cfg.device.guid] = cfg.device.displayName;
    return {'rows': rows, 'names': names};
  }

  @override
  State<HistoryLocator> createState() => _HistoryLocatorState();
}

class _HistoryLocatorState extends State<HistoryLocator> {
  late final metadata = widget.load(widget.id, null);
  final pages = <int, Future<Map<String, dynamic>>>{};
  ScrollController? scroll;
  DateTime? highlightStarted;

  @override
  void dispose() {
    scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: metadata,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return Center(child: Text(snapshot.error.toString()));
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final data = snapshot.requireData;
      final index = data['idx'] as int;
      return LayoutBuilder(
        builder: (context, box) {
          scroll ??= ScrollController(
            initialScrollOffset: max(
              0,
              (index ~/ widget.columns) * 150.0 - (box.maxHeight - 150) / 2,
            ),
          );
          return GridView.builder(
            controller: scroll,
            itemCount: data['total'],
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              mainAxisExtent: 150,
            ),
            itemBuilder: (context, i) {
              final start = i - i % HistoryLocator.pageSize;
              final page = pages.putIfAbsent(
                start,
                () => widget.load(widget.id, start),
              );
              if (pages.length > 12) pages.remove(pages.keys.first);
              return FutureBuilder<Map<String, dynamic>>(
                future: page,
                builder: (context, result) {
                  if (result.hasError)
                    return Center(child: Text(result.error.toString()));
                  if (!result.hasData) return const SizedBox.shrink();
                  final rows = result.requireData['rows'] as List;
                  if (i - start >= rows.length) return const SizedBox.shrink();
                  final r = rows[i - start];
                  final record = History.fromJson({
                    ...Map<String, dynamic>.from(r),
                    'top': r['top'] == 1,
                    'sync': r['sync'] == 1,
                  });
                  final card = widget.card(
                    ClipData(record),
                    result.requireData['names'][record.devId] ?? record.devId,
                  );
                  if (record.id != widget.id || data['duration'] == 0)
                    return card;
                  highlightStarted ??= DateTime.now();
                  final remaining =
                      (data['duration'] as int) -
                      DateTime.now()
                          .difference(highlightStarted!)
                          .inMilliseconds;
                  if (remaining <= 0) return card;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.35, end: 0),
                    duration: Duration(milliseconds: remaining),
                    child: card,
                    builder: (ctx, alpha, child) => DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.primary.withValues(alpha: alpha),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: child,
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}
