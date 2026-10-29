enum TransportProtocol {
  direct,
  server,
  webdav,
  s3;

  bool get isSocket => this == direct || this == server;

  bool get isStorage => this == webdav || this == s3;
}
