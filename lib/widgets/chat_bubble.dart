import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onTeach});

  final ChatMessage message;
  final VoidCallback? onTeach;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: user ? const Color(0x331E90FF) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: user ? const Color(0x661E90FF) : const Color(0x3300E5FF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text),
            if (message.unknownPhrase != null && onTeach != null)
              TextButton(
                onPressed: onTeach,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Teach this'),
              ),
          ],
        ),
      ),
    );
  }
}
