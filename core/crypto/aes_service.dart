import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class AESService {

  /// Generate random 256-bit key
  Uint8List generateKey() {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (_) => rnd.nextInt(256)),
    );
  }

  /// Generate random IV (16 bytes)
  Uint8List generateIV() {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => rnd.nextInt(256)),
    );
  }

  /// Encrypt using AES-CBC
  Map<String, String> encrypt(String plaintext, Uint8List key) {

    final iv = generateIV();

    final cipher = PaddedBlockCipher("AES/CBC/PKCS7")
      ..init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key), iv),
          null,
        ),
      );

    final encrypted = cipher.process(
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    return {
      "cipher": base64Encode(encrypted),
      "iv": base64Encode(iv),
    };
  }

  /// Decrypt AES
  String decrypt(String cipherText, Uint8List key, String ivBase64) {

    final iv = base64Decode(ivBase64);

    final cipher = PaddedBlockCipher("AES/CBC/PKCS7")
      ..init(
        false,
        PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key), iv),
          null,
        ),
      );

    final decrypted = cipher.process(base64Decode(cipherText));

    return utf8.decode(decrypted);
  }
}