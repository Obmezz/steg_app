import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';

import 'state/chat_provider.dart';
import 'state/contact_provider.dart';
import 'state/crypto_provider.dart';
import 'state/user_provider.dart';
import 'state/language_provider.dart';
import 'state/security_provider.dart';

import 'core/crypto/aes_service.dart';
import 'core/crypto/rsa_service.dart';
import 'core/crypto/hmac_service.dart';

import 'core/pipeline/encryption_pipeline.dart';
import 'core/pipeline/stego_pipeline.dart';

import 'services/message_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageProvider = LanguageProvider();
  final securityProvider = SecurityProvider();
  
  // Wait for critical settings to load to prevent multiple early rebuilds
  await Future.wait([
    languageProvider.loadSettings(),
    securityProvider.loadSettings(),
  ]);

  final aes = AESService();
  final rsa = RSAService();
  final hmac = HMACService();

  final encryptionPipeline = EncryptionPipeline(aes, rsa, hmac);
  final stegoPipeline = StegoPipeline();

  final cryptoProvider = CryptoProvider(encryptionPipeline);
  final messageRepo = MessageRepository();
  final contactProvider = ContactProvider(messageRepo);
  final userProvider = UserProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cryptoProvider),
        ChangeNotifierProvider.value(value: contactProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: securityProvider),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            cryptoProvider,
            stegoPipeline,
            messageRepo,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
