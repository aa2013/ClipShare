import 'dart:async';

import 'package:clipshare/core/providers/settings/app_paths/app_paths.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_paths_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AppPaths> appPaths(Ref ref) async {
  //todo
  return const AppPaths(
    rootStorePath: '',
    fileStorePath: '',
    screenShotStorePath: '',
    imageStorePath: '',
  );
}
