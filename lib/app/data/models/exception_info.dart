class ExceptionInfo {
  final dynamic err;
  final StackTrace stackTrace;

  ExceptionInfo({required this.err, required this.stackTrace});

  @override
  String toString() {
    return "$err, $stackTrace";
  }
}
