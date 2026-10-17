import 'package:flutter/material.dart';

import '../services/speech_service.dart';

/// Tap to start listening, tap again to stop. Never listens on its own,
/// and stops quietly if the screen goes away.
class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    required this.speech,
    required this.onPartial,
    required this.onFinal,
    required this.onMessage,
  });

  final SpeechService speech;
  final void Function(String text) onPartial;
  final void Function(String text) onFinal;
  final void Function(String message) onMessage;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  String _last = '';
  bool _busy = false;
  bool _closing = false;

  @override
  void dispose() {
    _closing = true;
    if (widget.speech.listening.value) widget.speech.stop();
    super.dispose();
  }

  bool get _alive => mounted && !_closing;

  Future<void> _toggle() async {
    if (_busy) return;
    if (widget.speech.listening.value) {
      await widget.speech.stop();
      return;
    }
    _busy = true;
    final problem = await widget.speech.prepare();
    _busy = false;
    if (!_alive) return;
    if (problem != null) {
      widget.onMessage(problem);
      return;
    }
    _last = '';
    await widget.speech.listen(
      onText: (t, isFinal) {
        _last = t;
        if (_alive) widget.onPartial(t);
      },
      onDone: () {
        if (!_alive) return;
        if (_last.trim().isEmpty) {
          widget.onMessage("Didn't hear anything. Tap the microphone and try again.");
        } else {
          widget.onFinal(_last);
        }
      },
      onError: (m) {
        if (_alive) widget.onMessage(m);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.speech.listening,
      builder: (context, listening, _) => IconButton(
        tooltip: listening ? 'Stop listening' : 'Microphone',
        icon: Icon(listening ? Icons.mic : Icons.mic_none),
        color: listening ? Theme.of(context).colorScheme.primary : null,
        onPressed: _toggle,
      ),
    );
  }
}
