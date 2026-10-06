class SocketCryptoConfig {
  ///密钥交换素数1
  final BigInt prime1;

  ///密钥交换素数2
  final BigInt prime2;

  ///密钥交换加密参数
  final String? dhAesKey;

  const SocketCryptoConfig({
    required this.prime1,
    required this.prime2,
    this.dhAesKey,
  });
}
