class SyncSettings {
  ///自动同步缺失数据
  final bool autoSyncMissingData;

  ///Android 屏幕解锁后自动复制
  final bool reCopyOnScreenUnlocked;

  ///Android 保存图片到相册
  final bool saveToPictures;

  ///图片同步后自动复制
  final bool autoCopyImageAfterSync;

  ///Android 自动复制截屏
  final bool autoCopyImageAfterScreenShot;

  ///同步数据范围
  final int syncOutdateLimitTime;

  const SyncSettings({
    this.autoSyncMissingData = true,
    this.reCopyOnScreenUnlocked = false,
    this.saveToPictures = false,
    this.autoCopyImageAfterSync = false,
    this.autoCopyImageAfterScreenShot = false,
    this.syncOutdateLimitTime = 0,
  });
}
