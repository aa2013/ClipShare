class DeviceConnectException implements Exception {
  final String message;

  const DeviceConnectException(this.message);

  @override
  String toString() => 'DeviceConnectException: $message';
}
