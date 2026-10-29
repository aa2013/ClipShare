class FetchUpdateLogsException implements Exception {
  final String message;
  FetchUpdateLogsException(this.message);

  @override
  String toString() => 'FetchUpdateLogsException: $message';
}