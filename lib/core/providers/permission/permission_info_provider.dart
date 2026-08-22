import 'package:clipshare/core/providers/permission/permission_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_info_provider.g.dart';

@Riverpod(keepAlive: true)
class PermissionInfoNotifier extends _$PermissionInfoNotifier {
  Future<PermissionInfo> build() async {
    return PermissionInfo();
  }
}
