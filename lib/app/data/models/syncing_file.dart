import 'dart:io';

import 'package:clipshare/app/data/enums/syncing_file_state.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SyncingFile {
  static const tag = "SyncingFile";
  final Device fromDev;
  final int totalSize;
  int _lastFlushBytes = 0;
  int _savedBytes = 0;
  DateTime _startTime = DateTime.now();
  final BuildContext context;
  final String filePath;
  final IOSink? _sink;
  final bool isSender;
  double speed = 0.0;
  final String _fileStartTime;
  SyncingFileState _state = SyncingFileState.wait;

  SyncingFileState get state => _state;

  void Function(bool done)? onClose;

  SyncingFile({
    required this.totalSize,
    required this.context,
    required this.filePath,
    required this.fromDev,
    IOSink? sink,
    required this.isSender,
    startTime,
    this.onClose,
  }) : _sink = sink,
       assert(totalSize >= 0),
       assert((!isSender && sink == null) || (sink != null || isSender)),
       _fileStartTime = startTime ?? DateTime.now().format("yyyy-MM-dd HH:mm:ss");

  String get startTime => _fileStartTime;

  int get lessTime => speed == 0 ? -1 : (totalSize - _savedBytes) ~/ speed;

  void addBytes(List<int> bytes) {
    if (_state == SyncingFileState.error) {
      return;
    }
    final syncingFileService = Get.find<SyncingFileProgressService>();
    if (_state != SyncingFileState.syncing) {
      _state = SyncingFileState.syncing;
      syncingFileService.updateSyncingFile(this);
    }
    if (!isSender) {
      try {
        _sink!.add(bytes);
        // await _sink.flush();
      } catch (err, stack) {
        Log.error(tag, "$filePath sync error. $err $stack");
        _state = SyncingFileState.error;
        syncingFileService.updateSyncingFile(this);
        return;
      }
    }
    final len = bytes.length;
    updateProgress(savedBytes + len);
  }

  void updateProgress(int newProgress) {
    final syncingFileService = Get.find<SyncingFileProgressService>();
    _savedBytes = newProgress;
    final now = DateTime.now();
    final offsetSeconds = now.difference(_startTime).inSeconds;
    final offsetMs = now.difference(_startTime).inMilliseconds;
    if (_savedBytes == totalSize || offsetSeconds >= 1) {
      _startTime = now;
      int offsetBytes = _savedBytes - _lastFlushBytes;
      speed = offsetBytes / (offsetMs / 1000);
      _lastFlushBytes = _savedBytes;
      syncingFileService.updateSyncingFile(this);
    }
  }

  int get savedBytes => _savedBytes;

  void setState(SyncingFileState state) {
    assert(isSender);
    _state = state;
    final syncingFileService = Get.find<SyncingFileProgressService>();
    syncingFileService.updateSyncingFile(this);
  }

  void close(bool done) {
    if (done) {
      _state = SyncingFileState.done;
    } else {
      _state = SyncingFileState.error;
    }
    final syncingFileService = Get.find<SyncingFileProgressService>();
    syncingFileService.updateSyncingFile(this);
    _sink?.close();
    onClose?.call(done);
  }
}
