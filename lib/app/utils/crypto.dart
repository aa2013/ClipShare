import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/export.dart';

class CryptoUtil {
  CryptoUtil._private();

  static String toMD5(Object obj) {
    var bytes = utf8.encode(obj.toString());
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  static Future<String?> calcFileMD5(String filePath) async {
    var file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }
    var res = md5.convert(await file.readAsBytes());
    return res.toString();
  }

  static String base64EncodeStr(String input) {
    List<int> bytes = utf8.encode(input);
    String encodedString = base64.encode(bytes);
    return encodedString;
  }

  static String base64EncodeBytes(List<int> bytes) {
    String encodedString = base64.encode(bytes);
    return encodedString;
  }

  static String base64DecodeStr(String input) {
    List<int> bytes = base64.decode(input);
    String decodedString = utf8.decode(bytes);
    return decodedString;
  }

  static List<int> base64DecodeBytes(String input) {
    return base64.decode(input);
  }

  /// 返回RSA的pem格式的key
  /// 第一个参数是 privateKey，第二个是 publicKey
  static List<String> genRSAKey() {
    AsymmetricKeyPair pair = CryptoUtils.generateRSAKeyPair();
    var privateKey = CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey as RSAPrivateKey);
    var publicKey = CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey as RSAPublicKey);
    return [privateKey, publicKey];
  }

  ///获取一个指定长度的素数
  static BigInt getPrime([int len = 2048]) {
    return generateProbablePrime(len, 1, CryptoUtils.getSecureRandom());
  }

  ///加密 RSA 数据
  static String encryptRSA(String publicKey, String data) {
    return CryptoUtils.rsaEncrypt(
      data,
      CryptoUtils.rsaPublicKeyFromPem(publicKey),
    );
  }

  ///解密 RSA 数据
  static String decryptRSA(String privateKey, String data) {
    return CryptoUtils.rsaDecrypt(
      data,
      CryptoUtils.rsaPrivateKeyFromPem(privateKey),
    );
  }

  static Encrypter getEncrypter(String key, [AESMode mode = AESMode.cbc]) {
    final aesKey = Key.fromUtf8(key);
    return Encrypter(AES(aesKey, mode: mode));
  }

  ///加密 AES 数据
  static String encryptAES({
    required String key,
    required String input,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    return (encrypter ?? getEncrypter(key)).encrypt(input, iv: iv).base64;
  }

  ///加密 AES 数据
  static Uint8List encryptAESAsBytes({
    required String key,
    required String input,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    return (encrypter ?? getEncrypter(key)).encrypt(input, iv: iv).bytes;
  }

  ///加密 AES 数据
  static Uint8List encryptAESWithBytes({
    required String key,
    required List<int> input,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    return (encrypter ?? getEncrypter(key)).encryptBytes(input, iv: iv).bytes;
  }

  ///解密 AES 数据
  static String decryptAES({
    required String key,
    required String encoded,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    return (encrypter ?? getEncrypter(key)).decrypt64(encoded, iv: iv);
  }

  ///解密 AES 数据
  static String decryptAESWithBytes({
    required String key,
    required Uint8List encoded,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    return (encrypter ?? getEncrypter(key)).decrypt(Encrypted(encoded), iv: iv);
  }

  ///解密 AES 数据
  static Uint8List decryptAESAsBytes({
    required String key,
    required Uint8List encoded,
    Encrypter? encrypter,
    int ivLen = 16,
  }) {
    final iv = IV.fromUtf8(key.substring(0, ivLen));
    final list = (encrypter ?? getEncrypter(key)).decryptBytes(Encrypted(encoded), iv: iv);
    return Uint8List.fromList(list);
  }

  static String generateRandomKey([
    int len = 16,
    String words = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ]) {
    final random = Random.secure();
    // 生成随机密钥
    var lst = List.generate(len, (_) => words[random.nextInt(words.length)]);
    return lst.join('');
  }

  ///密钥派生
  static Uint8List pbkdf2WithHmacSHA256Bytes(String password, String salt, int iterations, int keyLength) {
    final generator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(
        Pbkdf2Parameters(
          utf8.encode(salt),
          iterations,
          keyLength,
        ),
      );

    var result = generator.process(utf8.encode(password));
    // 将字节映射到可打印ASCII字符范围 (32-126)
    for (var i = 0; i < result.length; i++) {
      result[i] = 32 + (result[i] % 95); // 95个可打印字符
    }
    return result;
  }

  ///密钥派生
  static String pbkdf2WithHmacSHA256(String password, String salt, int iterations, int keyLength) {
    return ascii.decode(pbkdf2WithHmacSHA256Bytes(password, salt, iterations, keyLength));
  }
}

class DiffieHellman {
  late final BigInt _publicKey;
  final BigInt _g;
  final BigInt _p;
  final BigInt _privateKey;

  DiffieHellman(this._p, this._g, this._privateKey) {
    if (!isProbablePrime(_p, 1)) {
      throw Exception("p is not a prime number");
    }
    if (_g < BigInt.two || _g >= _p) {
      throw Exception("g must be between [2, p)");
    }
    _publicKey = _g.modPow(_privateKey, _p);
  }

  BigInt get publicKey => _publicKey;

  BigInt generateSharedSecret(BigInt publicKey) {
    return publicKey.modPow(_privateKey, _p);
  }

  /// test primality with certainty >= 1-.5^t */
  /// copy from [package:pointycastle/key_generators/rsa_key_generator.dart]
  static bool isProbablePrime(BigInt b, int t) {
    // Implementation borrowed from bignum.BigIntegerDartvm.
    int i;
    var x = b.abs();
    if (b <= _lowprimes.last) {
      for (i = 0; i < _lowprimes.length; ++i) {
        if (b == _lowprimes[i]) return true;
      }
      return false;
    }
    if (x.isEven) return false;
    i = 1;
    while (i < _lowprimes.length) {
      var m = _lowprimes[i], j = i + 1;
      while (j < _lowprimes.length && m < _lplim) {
        m *= _lowprimes[j++];
      }
      m = x % m;
      while (i < j) {
        if (m % _lowprimes[i++] == BigInt.zero) {
          return false;
        }
      }
    }
    return _millerRabin(x, t);
  }

  /// true if probably prime (HAC 4.24, Miller-Rabin) */
  /// copy from [package:pointycastle/key_generators/rsa_key_generator.dart]
  static bool _millerRabin(BigInt b, int t) {
    // Implementation borrowed from bignum.BigIntegerDartvm.
    var n1 = b - BigInt.one;
    var k = _lbit(n1);
    if (k <= 0) return false;
    var r = n1 >> k;
    t = (t + 1) >> 1;
    if (t > _lowprimes.length) t = _lowprimes.length;
    BigInt a;
    for (var i = 0; i < t; ++i) {
      a = _lowprimes[i];
      var y = a.modPow(r, b);
      if (y.compareTo(BigInt.one) != 0 && y.compareTo(n1) != 0) {
        var j = 1;
        while (j++ < k && y.compareTo(n1) != 0) {
          y = y.modPow(BigInt.two, b);
          if (y.compareTo(BigInt.one) == 0) return false;
        }
        if (y.compareTo(n1) != 0) return false;
      }
    }
    return true;
  }

  /// return index of lowest 1-bit in x, x < 2^31
  /// copy from [package:pointycastle/key_generators/rsa_key_generator.dart]
  static int _lbit(BigInt x) {
    // Implementation borrowed from bignum.BigIntegerDartvm.
    if (x == BigInt.zero) return -1;
    var r = 0;
    while ((x & BigInt.from(0xffffffff)) == BigInt.zero) {
      x >>= 32;
      r += 32;
    }
    if ((x & BigInt.from(0xffff)) == BigInt.zero) {
      x >>= 16;
      r += 16;
    }
    if ((x & BigInt.from(0xff)) == BigInt.zero) {
      x >>= 8;
      r += 8;
    }
    if ((x & BigInt.from(0xf)) == BigInt.zero) {
      x >>= 4;
      r += 4;
    }
    if ((x & BigInt.from(3)) == BigInt.zero) {
      x >>= 2;
      r += 2;
    }
    if ((x & BigInt.one) == BigInt.zero) ++r;
    return r;
  }

  /// [List] of low primes
  /// copy from [package:pointycastle/key_generators/rsa_key_generator.dart]
  static final List<BigInt> _lowprimes = [
    BigInt.from(2),
    BigInt.from(3),
    BigInt.from(5),
    BigInt.from(7),
    BigInt.from(11),
    BigInt.from(13),
    BigInt.from(17),
    BigInt.from(19),
    BigInt.from(23),
    BigInt.from(29),
    BigInt.from(31),
    BigInt.from(37),
    BigInt.from(41),
    BigInt.from(43),
    BigInt.from(47),
    BigInt.from(53),
    BigInt.from(59),
    BigInt.from(61),
    BigInt.from(67),
    BigInt.from(71),
    BigInt.from(73),
    BigInt.from(79),
    BigInt.from(83),
    BigInt.from(89),
    BigInt.from(97),
    BigInt.from(101),
    BigInt.from(103),
    BigInt.from(107),
    BigInt.from(109),
    BigInt.from(113),
    BigInt.from(127),
    BigInt.from(131),
    BigInt.from(137),
    BigInt.from(139),
    BigInt.from(149),
    BigInt.from(151),
    BigInt.from(157),
    BigInt.from(163),
    BigInt.from(167),
    BigInt.from(173),
    BigInt.from(179),
    BigInt.from(181),
    BigInt.from(191),
    BigInt.from(193),
    BigInt.from(197),
    BigInt.from(199),
    BigInt.from(211),
    BigInt.from(223),
    BigInt.from(227),
    BigInt.from(229),
    BigInt.from(233),
    BigInt.from(239),
    BigInt.from(241),
    BigInt.from(251),
    BigInt.from(257),
    BigInt.from(263),
    BigInt.from(269),
    BigInt.from(271),
    BigInt.from(277),
    BigInt.from(281),
    BigInt.from(283),
    BigInt.from(293),
    BigInt.from(307),
    BigInt.from(311),
    BigInt.from(313),
    BigInt.from(317),
    BigInt.from(331),
    BigInt.from(337),
    BigInt.from(347),
    BigInt.from(349),
    BigInt.from(353),
    BigInt.from(359),
    BigInt.from(367),
    BigInt.from(373),
    BigInt.from(379),
    BigInt.from(383),
    BigInt.from(389),
    BigInt.from(397),
    BigInt.from(401),
    BigInt.from(409),
    BigInt.from(419),
    BigInt.from(421),
    BigInt.from(431),
    BigInt.from(433),
    BigInt.from(439),
    BigInt.from(443),
    BigInt.from(449),
    BigInt.from(457),
    BigInt.from(461),
    BigInt.from(463),
    BigInt.from(467),
    BigInt.from(479),
    BigInt.from(487),
    BigInt.from(491),
    BigInt.from(499),
    BigInt.from(503),
    BigInt.from(509),
  ];

  /// copy from [package:pointycastle/key_generators/rsa_key_generator.dart]
  static final BigInt _lplim = (BigInt.one << 26) ~/ _lowprimes.last;
}
