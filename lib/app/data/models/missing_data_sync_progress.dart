class MissingDataSyncProgress {
  int seq;
  int syncedCount = 1;
  int total;
  bool? firstHistory;

  MissingDataSyncProgress(this.seq, this.total, [this.firstHistory]);

  MissingDataSyncProgress copy() {
    return MissingDataSyncProgress(seq, total)
      ..syncedCount = syncedCount
      ..firstHistory = firstHistory;
  }

  bool get hasCompleted => syncedCount >= total;
}
