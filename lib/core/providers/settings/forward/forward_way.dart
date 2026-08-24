enum ForwardWay {
  server,
  webdav,
  s3,
  none;

  static final storageWays = List<ForwardWay>.unmodifiable([webdav, s3]);
}
