part of 'clip_channel_provider.dart';

Future _onMethodCall(Ref ref, MethodCall call) async {
  var arguments = call.arguments;
  var method = ClipChannelMethod.values.byName(call.method);
  final historyDao = ref.read(appDbProvider).requireValue.historyDao;
  switch (method) {
    case ClipChannelMethod.ignoreNextCopy:
      break;
    case ClipChannelMethod.setTop:
      int id = arguments['id'];
      bool top = arguments['top'];
      final cnt = await historyDao.setTop(id, top);
      if (cnt != null && cnt > 0) {
        final recorder = ref.read(historyRecorderProvider.notifier);
        final history = await historyDao.getById(id);
        if (history == null) {
          return false;
        }
        recorder.addDelta(
          HistoryDeltaEvent(
            history: history,
            operation: OpMethod.update,
          ),
        );
        return true;
      }
      return false;
    case ClipChannelMethod.getHistory:
      int fromId = arguments['fromId'];
      var lst = List<History>.empty();
      if (fromId == 0) {
        lst = await historyDao.getHistoriesTop100(historyFloatTypes);
      } else {
        lst = await historyDao.getHistoriesPage(fromId, historyFloatTypes);
      }
      var contentLst = lst
          .map(
            (e) => {
              'id': e.id,
              'content': e.content,
              'time': e.time,
              'top': e.top,
              'type': e.type,
            },
          )
          .toList();
      return Future(() => contentLst);
    default:
  }
  return Future(() => false);
}
