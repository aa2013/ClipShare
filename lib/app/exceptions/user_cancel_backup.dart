class UserCancelBackup extends Error {
  @override
  String toString() {
    return "user cancel backup or restore";
  }
}
