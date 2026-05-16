import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.type == "sent";
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: isMe ? 64 : 16,
              right: isMe ? 16 : 64,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: message.text != null
                ? Text(
                    message.text!,
                    style: TextStyle(
                      color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  )
                : message.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(
                              File(message.imagePath!),
                              fit: BoxFit.cover,
                            ),
                            if (isMe)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock, size: 14, color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: isMe ? colorScheme.onPrimary.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Encrypted Data",
                            style: TextStyle(
                              color: isMe ? colorScheme.onPrimary.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 20,
              right: isMe ? 20 : 0,
              bottom: 8,
            ),
            child: Text(
              isMe ? "Sent" : "Received",
              style: TextStyle(fontSize: 10, color: colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
