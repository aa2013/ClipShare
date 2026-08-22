class DataTooLargeException implements Exception {
  final String message;
  DataTooLargeException(this.message);

  @override
  String toString() => 'DataTooLargeException: $message';
}