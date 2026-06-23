import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/obj_storage_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_storage_integration_test_config.dart';
import 'remote_storage_integration_test_target.dart';

void main() {
  group('RemoteStorageIntegrationTestConfigLoader', () {
    test('loadTargets parses mixed webdav s3 and aliyun oss targets', () async {
      final tempDir = await Directory.systemTemp.createTemp('codex-storage-config-');
      final configFile = File('${tempDir.path}/remote-storage.json');

      try {
        await configFile.writeAsString(
          jsonEncode(<String, Object?>{
            'targets': <Object?>[
              <String, Object?>{
                "enabled": true,
                'storageType': 'webdav',
                'config': <String, Object?>{
                  'displayName': 'webdav-demo',
                  'server': 'https://example.com/webdav',
                  'username': 'demo-user',
                  'password': 'demo-pass',
                  'baseDir': '/demo',
                },
              },
              <String, Object?>{
                "enabled": true,
                'storageType': 's3',
                'config': <String, Object?>{
                  'displayName': 's3-demo',
                  'endPoint': 's3.amazonaws.com',
                  'accessKey': 'demo-ak',
                  'secretKey': 'demo-sk',
                  'bucketName': 'demo-bucket',
                  'baseDir': '/demo',
                  'region': 'ap-southeast-1',
                  'pathStyle': false,
                  'type': 's3',
                },
              },
              <String, Object?>{
                "enabled": true,
                'storageType': 's3',
                'config': <String, Object?>{
                  'displayName': 'oss-demo',
                  'endPoint': 'oss-cn-hangzhou.aliyuncs.com',
                  'accessKey': 'demo-ak',
                  'secretKey': 'demo-sk',
                  'bucketName': 'demo-bucket',
                  'baseDir': '/demo',
                  'region': 'cn-hangzhou',
                  'pathStyle': false,
                  'type': 'aliyunOss',
                },
              },
            ],
          }),
        );

        final targets = RemoteStorageIntegrationTestConfigLoader.loadTargets(
          configPath: configFile.path,
        );

        expect(targets, hasLength(3));
        expect(targets[0], isA<WebDavIntegrationTarget>());
        expect(targets[0].kind, RemoteStorageIntegrationKind.webdav);
        expect(targets[1], isA<S3IntegrationTarget>());
        expect((targets[1] as S3IntegrationTarget).config.type, ObjStorageType.s3);
        expect((targets[2] as S3IntegrationTarget).config.type, ObjStorageType.aliyunOss);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('hasLocalConfig returns whether the given file exists', () async {
      final tempDir = await Directory.systemTemp.createTemp('codex-storage-has-config-');
      final configFile = File('${tempDir.path}/remote-storage.json');

      try {
        expect(
          RemoteStorageIntegrationTestConfigLoader.hasLocalConfig(
            configPath: configFile.path,
          ),
          isFalse,
        );

        await configFile.writeAsString('{}');

        expect(
          RemoteStorageIntegrationTestConfigLoader.hasLocalConfig(
            configPath: configFile.path,
          ),
          isTrue,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('loadTargets fails for unsupported storageType', () async {
      final tempDir = await Directory.systemTemp.createTemp('codex-storage-invalid-type-');
      final configFile = File('${tempDir.path}/remote-storage.json');

      try {
        await configFile.writeAsString(
          jsonEncode(<String, Object?>{
            'targets': <Object?>[
              <String, Object?>{
                'storageType': 'ftp',
                'config': <String, Object?>{},
              },
            ],
          }),
        );

        expect(
          () => RemoteStorageIntegrationTestConfigLoader.loadTargets(
            configPath: configFile.path,
          ),
          throwsA(
            isA<TestFailure>().having(
              (err) => err.message,
              'message',
              contains('unsupported storageType "ftp"'),
            ),
          ),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('loadTargets fails when targets is missing or empty', () async {
      final tempDir = await Directory.systemTemp.createTemp('codex-storage-empty-targets-');
      final configFile = File('${tempDir.path}/remote-storage.json');

      try {
        await configFile.writeAsString(
          jsonEncode(<String, Object?>{
            'targets': <Object?>[],
          }),
        );

        expect(
          () => RemoteStorageIntegrationTestConfigLoader.loadTargets(
            configPath: configFile.path,
          ),
          throwsA(
            isA<TestFailure>().having(
              (err) => err.message,
              'message',
              contains('"targets" must be a non-empty array'),
            ),
          ),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('loadTargets fails when config is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp('codex-storage-missing-config-');
      final configFile = File('${tempDir.path}/remote-storage.json');

      try {
        await configFile.writeAsString(
          jsonEncode(<String, Object?>{
            'targets': <Object?>[
              <String, Object?>{
                'storageType': 'webdav',
              },
            ],
          }),
        );

        expect(
          () => RemoteStorageIntegrationTestConfigLoader.loadTargets(
            configPath: configFile.path,
          ),
          throwsA(
            isA<TestFailure>().having(
              (err) => err.message,
              'message',
              contains('"config" must be an object'),
            ),
          ),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
