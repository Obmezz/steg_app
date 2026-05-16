import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/chat_provider.dart';
import '../../models/message_model.dart';

import '../../state/language_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/helpers.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmClear(context, lang),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, child) {
          if (chat.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('no_messages'),
                    style: TextStyle(color: colorScheme.outline, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chat.messages.length,
            itemBuilder: (context, index) {
              final msg = chat.messages[index];
              final isSent = msg.type == 'sent';
              final hasImage = msg.imagePath != null && File(msg.imagePath!).existsSync();

              return Card(
                elevation: 0,
                color: isSent ? colorScheme.primaryContainer.withValues(alpha: 0.3) : colorScheme.secondaryContainer.withValues(alpha: 0.3),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSent ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
                  ),
                ),
                child: ListTile(
                  onTap: () => _showMessageDetails(context, msg, lang),
                  leading: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(msg.imagePath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: isSent ? colorScheme.primary : colorScheme.secondary,
                          child: Icon(
                            isSent ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                            color: isSent ? colorScheme.onPrimary : colorScheme.onSecondary,
                            size: 20,
                          ),
                        ),
                  title: Text(
                    isSent ? lang.translate('sent') : lang.translate('received'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    msg.text ?? (isSent ? lang.translate('encrypted_data') : "No text content"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right, size: 16, color: colorScheme.outline),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMessageDetails(BuildContext context, MessageModel msg, LanguageProvider lang) {
    final isSent = msg.type == 'sent';
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSent ? "${lang.translate('sent')} ${lang.translate('details')}" : "${lang.translate('received')} ${lang.translate('details')}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.imagePath != null && File(msg.imagePath!).existsSync()) ...[
                Text("${lang.translate('encrypted_data')}:", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(msg.imagePath!)),
                ),
                const SizedBox(height: 16),
              ],
              Text("${lang.translate('profile')}:", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  msg.text ?? (isSent ? lang.translate('encrypted_data') : "No content"),
                  style: TextStyle(
                    fontFamily: isSent ? 'monospace' : null,
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (msg.imagePath != null && File(msg.imagePath!).existsSync())
            TextButton(
              onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(msg.imagePath!)])),
              child: Text(lang.translate('share')),
            ),
          if (isSent && msg.imagePath != null)
            TextButton(
              onPressed: () => _attemptReDecode(context, msg),
              child: Text(lang.translate('extract').toUpperCase()),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('got_it').toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _attemptReDecode(BuildContext context, MessageModel msg) {
    try {
      final chat = context.read<ChatProvider>();
      final payload = chat.stego.decode(File(msg.imagePath!));
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Extracted Data"),
          content: SingleChildScrollView(
            child: Text(
              payload,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        UiHelpers.showSnackBar(context, Provider.of<LanguageProvider>(context, listen: false).translate('decode_failed'), isError: true);
      }
    }
  }

  void _confirmClear(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('clear_history')),
        content: Text(lang.translate('clear_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().repo.clearMessages();
              context.read<ChatProvider>().loadHistory();
              Navigator.pop(context);
            },
            child: Text(lang.translate('clear_all'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
