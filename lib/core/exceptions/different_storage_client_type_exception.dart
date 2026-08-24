class DifferentStorageClientTypeException implements Exception {
  final String message;
  DifferentStorageClientTypeException(this.message);

  @override
  String toString() => 'DifferentStorageClientType: $message';
}