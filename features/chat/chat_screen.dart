import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/chat_provider.dart';
import '../../state/language_provider.dart';
import '../../core/security/key_storage.dart';
import '../../utils/helpers.dart';

import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _processedInitialImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_processedInitialImage) {
      final image = ModalRoute.of(context)?.settings.arguments as File?;
      if (image != null) {
        _handleReceiveImage(image);
      }
      _processedInitialImage = true;
    }
  }

  Future<void> _handleReceiveImage(File image) async {
    final chat = context.read<ChatProvider>();
    final lang = context.read<LanguageProvider>();
    final keyStorage = KeyStorage();
    
    try {
      final privateKeyString = await keyStorage.getPrivateKey();
      if (privateKeyString == null) throw "Private key not found";
      
      final privateKey = KeyHelper.decodePrivateKey(privateKeyString);
      
      await chat.receiveMessage(
        image: image,
        privateKey: privateKey,
      );
      
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('decode_success'));
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('decode_failed'), isError: true);
      }
    }
  }

  void _showEncryptionInfo(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('encryption_info_title')),
        content: Text(lang.translate('encryption_info_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('got_it').toUpperCase()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final lang = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.translate('encrypted_channel')),
            Text(
              lang.translate('e2e_encrypted'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showEncryptionInfo(context, lang),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_person_rounded,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.translate('no_messages'),
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          lang.translate('secured_with'),
                          style: TextStyle(
                            color: colorScheme.outlineVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, i) {
                      return MessageBubble(
                        message: chat.messages[i],
                      );
                    },
                  ),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
