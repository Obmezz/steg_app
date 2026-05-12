import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class RSAService {

  /// 🔐 Generate RSA key pair (2048-bit)
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair() {
    final keyGen = KeyGenerator('RSA');
    final secureRandom = FortunaRandom();

    // seed generator
    final seed = Uint8List(32);
    final random = Random.secure();

    for (int i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }

    secureRandom.seed(KeyParameter(seed));

    keyGen.init(
      ParametersWithRandom<CipherParameters>(
        RSAKeyGeneratorParameters(
          BigInt.parse('65537'),
          2048,
          12,
        ),
        secureRandom,
      ),
    );

    final pair = keyGen.generateKeyPair();

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  /// 🔐 Encrypt AES key using RSA public key
  Uint8List encrypt(Uint8List data, RSAPublicKey publicKey) {
    final engine = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    return engine.process(data);
  }

  /// 🔓 Decrypt AES key using RSA private key
  Uint8List decrypt(Uint8List cipher, RSAPrivateKey privateKey) {
    final engine = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    return engine.process(cipher);
  }
}
