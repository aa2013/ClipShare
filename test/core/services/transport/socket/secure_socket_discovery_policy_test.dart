import 'dart:io';

import 'package:clipshare/core/database/tables/device.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/client/socket/secure_socket_client.dart';
import 'package:clipshare/core/services/transport/client/socket/secure_socket_server.dart';
import 'package:clipshare/core/services/transport/models/local_socket_base_info.dart';
import 'package:clipshare/core/services/transport/models/socket_crypto_config.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定小素数，避免生成 2048 位素数的开销，且共享密钥长度满足 AES key 的 32 字符截断。
final _testPrime = (BigInt.one << 255) - BigInt.from(19);
final _testPrivateKey = BigInt.parse('1234567890123456789012345678901234567890');

LocalSocketBaseInfo _baseInfo(String guid) {
  return LocalSocketBaseInfo(
    cryptoConfig: SocketCryptoConfig(prime1: _testPrime, prime2: _testPrivateKey),
    baseDeviceInfo: BaseDeviceInfo(guid: guid, name: guid, type: PlatformType.windows),
    localListenPort: 0,
    localVersion: const AppVersion('1.0.0', '100'),
    minVersion: const AppVersion('1.0.0', '100'),
  );
}

Future<int> _pickFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<SecureSocketServer> _bindServer({
  required int port,
  required bool Function() allowUnpairedConnection,
  required Device? Function(String guid) loadDevice,
}) {
  return SecureSocketServer.bind(
    ip: InternetAddress.loopbackIPv4.address,
    port: port,
    baseInfo: _baseInfo('server'),
    allowUnpairedConnection: allowUnpairedConnection,
    loadDevice: loadDevice,
    onConnected: (_, __) {},
    onMessage: (_, __) {},
  );
}

Future<SecureSocketClient> _connectClient({
  required int port,
  required bool Function() allowUnpairedConnection,
  required Device? Function(String guid) loadDevice,
}) {
  return SecureSocketClient.connect(
    ip: InternetAddress.loopbackIPv4.address,
    port: port,
    localBaseInfo: _baseInfo('client'),
    allowUnpairedConnection: allowUnpairedConnection,
    loadDevice: loadDevice,
  );
}

Device? _noDevice(String guid) => null;

Device? _pairedDevice(String guid) => emptyDevice(
  guid: guid,
  devName: guid,
  type: 'windows',
  isPaired: true,
);

/// 用真实本地 socket 执行完整握手，验证未配对设备准入策略。
void main() {
  test('服务端关闭可被发现时拒绝未配对设备', () async {
    final port = await _pickFreePort();
    final server = await _bindServer(
      port: port,
      allowUnpairedConnection: () => false,
      loadDevice: _noDevice,
    );
    addTearDown(server.close);

    await expectLater(
      _connectClient(
        port: port,
        allowUnpairedConnection: () => true,
        loadDevice: _noDevice,
      ),
      throwsA(anything),
    );
  });

  test('服务端开启可被发现时接受未配对设备', () async {
    final port = await _pickFreePort();
    final server = await _bindServer(
      port: port,
      allowUnpairedConnection: () => true,
      loadDevice: _noDevice,
    );
    addTearDown(server.close);

    final client = await _connectClient(
      port: port,
      allowUnpairedConnection: () => true,
      loadDevice: _noDevice,
    );
    addTearDown(client.close);

    expect(client.isReady, isTrue);
  });

  test('已配对设备不受可被发现开关影响', () async {
    final port = await _pickFreePort();
    final server = await _bindServer(
      port: port,
      allowUnpairedConnection: () => false,
      loadDevice: _pairedDevice,
    );
    addTearDown(server.close);

    final client = await _connectClient(
      port: port,
      allowUnpairedConnection: () => false,
      loadDevice: _pairedDevice,
    );
    addTearDown(client.close);

    expect(client.isReady, isTrue);
  });

  test('服务端在握手时实时读取准入策略', () async {
    final port = await _pickFreePort();
    var allowUnpaired = false;
    final server = await _bindServer(
      port: port,
      allowUnpairedConnection: () => allowUnpaired,
      loadDevice: _noDevice,
    );
    addTearDown(server.close);

    await expectLater(
      _connectClient(
        port: port,
        allowUnpairedConnection: () => true,
        loadDevice: _noDevice,
      ),
      throwsA(anything),
    );

    allowUnpaired = true;
    final client = await _connectClient(
      port: port,
      allowUnpairedConnection: () => true,
      loadDevice: _noDevice,
    );
    addTearDown(client.close);

    expect(client.isReady, isTrue);
  });

  test('发起端关闭可被发现时拒绝未配对设备', () async {
    final port = await _pickFreePort();
    final server = await _bindServer(
      port: port,
      allowUnpairedConnection: () => true,
      loadDevice: _noDevice,
    );
    addTearDown(server.close);

    await expectLater(
      _connectClient(
        port: port,
        allowUnpairedConnection: () => false,
        loadDevice: _noDevice,
      ),
      throwsA(anything),
    );
  });
}
