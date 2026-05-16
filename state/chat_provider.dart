import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../models/encrypted_payload.dart';

import '../core/pipeline/stego_pipeline.dart';
import '../services/message_repository.dart';
import 'crypto_provider.dart';

import 'package:pointycastle/export.dart';

class ChatProvider extends ChangeNotifier {

  final CryptoProvider crypto;
  final StegoPipeline stego;
  final MessageRepository repo;

  ChatProvider(this.crypto, this.stego, this.repo);

  final List<MessageModel> messages = [];

  Future<void> loadHistory() async {
    final history = await repo.getMessages();
    messages.clear();
    for (var m in history) {
      final type = m['type'] as String;
      messages.add(
        MessageModel(
          type: type,
          text: type == 'received' ? m['data'] as String? : "Sent Secret Payload",
          imagePath: m['imagePath'] as String?,
        ),
      );
    }
    notifyListeners();
  }

  /// 📤 SEND MESSAGE (FULL PIPELINE)
  Future<File> sendMessage({
    required String text,
    required RSAPublicKey recipientKey,
    required File image,
  }) async {

    // 1. Encrypt message
    final encrypted = crypto.encrypt(
      message: text,
      recipientKey: recipientKey,
    );

    // 2. Convert payload → JSON string
    final payloadJson = jsonEncode(encrypted.toJson());

    // 3. Hide inside image (stego)
    final stegoImage = stego.encode(image, payloadJson);

    // 4. Save to DB
    await repo.insert(payloadJson, "sent", imagePath: stegoImage.path);

    // 5. UI update
    messages.add(
      MessageModel(
        type: "sent",
        imagePath: stegoImage.path,
      ),
    );

    notifyListeners();
    return stegoImage;
  }

  /// 📥 RECEIVE MESSAGE (FULL PIPELINE)
  Future<void> receiveMessage({
    required File image,
    required RSAPrivateKey privateKey,
  }) async {

    // 1. Extract payload from image
    final extractedJson = stego.decode(image);

    // 2. Parse JSON and restore payload
    final Map<String, dynamic> payloadMap = jsonDecode(extractedJson) as Map<String, dynamic>;
    final payload = EncryptedPayload.fromJson(payloadMap);

    // 3. Decrypt message
    final message = crypto.decrypt(
      payload: payload,
      privateKey: privateKey,
    );

    // 4. Save
    await repo.insert(message, "received", imagePath: image.path);

    // 5. UI update
    messages.add(
      MessageModel(
        type: "received",
        text: message,
        imagePath: image.path,
      ),
    );

    notifyListeners();
  }
}
