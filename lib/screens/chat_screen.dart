import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/app_services.dart';
import '../services/command_engine.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/voice_button.dart';
import 'teach_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.services, this.initialMessage});

  final AppServices services;
  final String? initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _messages = <ChatMessage>[];
  AppServices get _s => widget.services;
  late final CommandEngine _engine = CommandEngine(_s.store);

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
    _s.tts.stop();
    _input.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _speak(String text) async {
    if (!_s.settings.speakReplies) return;
    await _s.tts.stop();
    final problem = await _s.tts.speak(text, rate: _s.settings.speechRate);
    if (problem != null && mounted) _toast(problem);
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
    _speak(reply.text);
  }

  Future<void> _teach(String phrase) async {
    final saved = await showTeachDialog(context, _s.store, phrase: phrase);
    if (!saved || !mounted) return;
    setState(() => _messages.add(const ChatMessage(
        "Saved. Say it again and I'll reply.",
        fromUser: false)));
  }

  void _sendTyped() {
    final text = _input.text;
    _input.clear();
    _submit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _s.tts.speaking,
            builder: (context, speaking, _) => IconButton(
              tooltip: 'Stop speaking',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: speaking ? () => _s.tts.stop() : null,
            ),
          ),
          IconButton(
            tooltip: 'Taught commands',
            icon: const Icon(Icons.school_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TeachScreen(store: _s.store))),
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
                      onSubmitted: (_) => _sendTyped(),
                      decoration: const InputDecoration(
                          hintText: 'Type a message', border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _sendTyped,
                  ),
                  VoiceButton(
                    speech: _s.speech,
                    onPartial: (t) {
                      _input.text = t;
                      _input.selection = TextSelection.collapsed(offset: t.length);
                    },
                    onFinal: (t) {
                      _input.clear();
                      _submit(t);
                    },
                    onMessage: _toast,
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
