import 'dart:convert';

import '../crypto/aes_service.dart';
import '../crypto/rsa_service.dart';
import '../crypto/hmac_service.dart';

import '../../models/encrypted_payload.dart';
import 'package:pointycastle/export.dart';

class EncryptionPipeline {

  final AESService aes;
  final RSAService rsa;
  final HMACService hmac;

  EncryptionPipeline(this.aes, this.rsa, this.hmac);

  /// 🔐 ENCRYPT
  EncryptedPayload encryptMessage({
    required String message,
    required RSAPublicKey recipientKey,
  }) {

    // 1. AES key
    final aesKey = aes.generateKey();

    // 2. Encrypt message
    final aesResult = aes.encrypt(message, aesKey);

    // 3. Encrypt AES key with RSA
    final encryptedKey = rsa.encrypt(aesKey, recipientKey);

    // 4. HMAC signature
    final signature = hmac.generate(
      aesResult["cipher"]!,
      aesKey,
    );

    return EncryptedPayload(
      encryptedKey: encryptedKey,
      encryptedMessage: base64Decode(aesResult["cipher"]!),
      iv: base64Decode(aesResult["iv"]!),
      signature: base64Decode(signature),
    );
  }

  /// 🔓 DECRYPT
  String decryptMessage({
    required EncryptedPayload payload,
    required RSAPrivateKey privateKey,
  }) {

    // 1. Recover AES key
    final aesKey = rsa.decrypt(
      payload.encryptedKey,
      privateKey,
    );

    // 2. Verify HMAC
    final valid = hmac.verify(
      base64Encode(payload.encryptedMessage),
      base64Encode(payload.signature),
      aesKey,
    );

    if (!valid) {
      throw Exception("Integrity check failed (HMAC mismatch)");
    }

    // 3. Decrypt message
    return aes.decrypt(
      base64Encode(payload.encryptedMessage),
      aesKey,
      base64Encode(payload.iv),
    );
  }
}
