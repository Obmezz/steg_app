import 'package:flutter/material.dart';
import '../core/pipeline/encryption_pipeline.dart';
import '../models/encrypted_payload.dart';
import 'package:pointycastle/export.dart';

class CryptoProvider extends ChangeNotifier {

  final EncryptionPipeline pipeline;

  CryptoProvider(this.pipeline);

  /// Encrypt message for recipient
  EncryptedPayload encrypt({
    required String message,
    required RSAPublicKey recipientKey,
  }) {
    return pipeline.encryptMessage(
      message: message,
      recipientKey: recipientKey,
    );
  }

  /// Decrypt received message
  String decrypt({
    required EncryptedPayload payload,
    required RSAPrivateKey privateKey,
  }) {
    return pipeline.decryptMessage(
      payload: payload,
      privateKey: privateKey,
    );
  }
}