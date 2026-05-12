import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../../../state/chat_provider.dart';
import '../../../state/language_provider.dart';
import '../../../services/image_service.dart';
import '../../../models/contact_model.dart';
import '../../contacts/contact_selection_screen.dart';

import '../../../utils/helpers.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final controller = TextEditingController();
  final imageService = ImageService();

  File? image;

  Future<void> _handleSend() async {
    final lang = context.read<LanguageProvider>();
    if (image == null) {
      UiHelpers.showSnackBar(context, lang.translate('select_image_first'), isError: true);
      return;
    }

    if (controller.text.isEmpty) {
      UiHelpers.showSnackBar(context, lang.translate('enter_secret_message'), isError: true);
      return;
    }

    // 1. Pick Recipient
    final ContactModel? contact = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(builder: (context) => const ContactSelectionScreen()),
    );

    if (contact == null || !mounted) return;

    try {
      if (mounted) {
        final stegoProvider = context.read<ChatProvider>();
        final stegoFile = await stegoProvider.sendMessage(
          text: controller.text,
          recipientKey: KeyHelper.decodePublicKey(contact.publicKey),
          image: image!,
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(lang.translate('message_hidden')),
              content: Text(lang.translate('hidden_action_prompt')),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Gal.putImage(stegoFile.path);
                    if (mounted && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      UiHelpers.showSnackBar(context, lang.translate('saved_to_gallery'));
                    }
                  },
                  child: Text(lang.translate('save_to_gallery')),
                ),
                TextButton(
                  onPressed: () async {
                    await Share.shareXFiles([XFile(stegoFile.path)], text: 'Secure Image');
                    if (mounted && dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(lang.translate('share')),
                ),
              ],
            ),
          );
        }

        setState(() {
          image = null;
          controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showSnackBar(context, lang.translate('operation_failed'), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: image != null ? Colors.green : null),
            onPressed: () async {
              final picked = await imageService.pickImage();
              if (picked != null) {
                setState(() => image = picked);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: lang.translate('type_secret_hint'),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
