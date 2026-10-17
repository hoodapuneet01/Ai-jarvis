import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/command_engine.dart';
import '../services/command_store.dart';
import '../widgets/chat_bubble.dart';
import 'teach_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store, this.initialMessage});

  final CommandStore store;
  final String? initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _messages = <ChatMessage>[];
  late final CommandEngine _engine = CommandEngine(widget.store);

  @override
  void initState() {
    super.initState();
    final first = widget.initialMessage;
    if (first != null && first.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit(first);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(ChatMessage(text, fromUser: true)));
    ChatMessage reply;
    try {
      final match = await _engine.match(text);
      reply = match == null
          ? ChatMessage("I haven't been taught that yet.",
              fromUser: false, unknownPhrase: text)
          : ChatMessage(match.response, fromUser: false);
    } catch (e) {
      reply = ChatMessage("Couldn't read taught commands: $e", fromUser: false);
    }
    if (!mounted) return;
    setState(() => _messages.add(reply));
  }

  Future<void> _teach(String phrase) async {
    final saved = await showTeachDialog(context, widget.store, phrase: phrase);
    if (!saved || !mounted) return;
    setState(() => _messages.add(const ChatMessage(
        "Saved. Say it again and I'll reply.",
        fromUser: false)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            tooltip: 'Taught commands',
            icon: const Icon(Icons.school_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TeachScreen(store: widget.store))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        "Say something. I only know commands you've taught me.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[_messages.length - 1 - i];
                      return ChatBubble(
                        message: m,
                        onTeach: m.unknownPhrase == null
                            ? null
                            : () => _teach(m.unknownPhrase!),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) {
                        _submit(v);
                        _input.clear();
                      },
                      decoration: const InputDecoration(
                          hintText: 'Type a message', border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () {
                      _submit(_input.text);
                      _input.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
