import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/utils/log.dart';

abstract class HistoryDataObserver {
  void onChanged(HistoryContentType type, String content, ClipboardSource? source);
}

class HistoryDataListener {
  static const String tag = "HistoryDataListener";

  static final List<HistoryDataObserver> _list = List.empty(growable: true);
  static final HistoryDataListener _instance = HistoryDataListener._private();

  HistoryDataListener._private();

  static HistoryDataListener get inst => _instance;

  HistoryDataListener register(HistoryDataObserver observer) {
    _list.add(observer);
    return this;
  }

  HistoryDataListener remove(HistoryDataObserver observer) {
    _list.remove(observer);
    return this;
  }

  void onChanged(HistoryContentType type, String content, ClipboardSource? source) {
    for (var observer in _list) {
      try {
        observer.onChanged(type, content, source);
      } catch (e, stacktrace) {
        Log.debug(tag, e);
        Log.debug(tag, stacktrace);
      }
    }
  }
}
