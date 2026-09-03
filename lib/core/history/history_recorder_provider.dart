
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'history_recorder.dart';

part 'history_recorder_provider.g.dart';

@Riverpod(keepAlive: true)
HistoryRecorder historyRecorder(Ref ref) {
  final recorder = HistoryRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
}
