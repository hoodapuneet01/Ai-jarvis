import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/core_state.dart';
import '../services/app_services.dart';
import '../widgets/ai_core.dart';
import '../widgets/glass_panel.dart';
import '../widgets/particle_field.dart';
import '../widgets/status_indicator.dart';
import '../widgets/voice_button.dart';
import 'chat_screen.dart';
import 'feature_stub_screen.dart';
import 'settings_screen.dart';
import 'teach_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController();
  AppServices get _s => widget.services;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  CoreState _currentState() {
    if (_s.speech.listening.value) return CoreState.listening;
    if (_s.tts.speaking.value) return CoreState.speaking;
    return CoreState.idle;
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(services: _s, initialMessage: text),
    ));
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_s.speech.listening, _s.tts.speaking]),
      builder: (context, _) {
        final state = _currentState();
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: ParticleField(color: state.color)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Clock(),
                          const Spacer(),
                          Flexible(
                            child: StatusIndicator(
                              label: 'Local commands, no AI model',
                              color: CoreState.idle.color,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final s = math.min(box.maxWidth, box.maxHeight);
                            return Center(child: AiCore(state: state, size: s));
                          },
                        ),
                      ),
                      Text(
                        state.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: state.color,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const GlassPanel(
                        child: Column(
                          children: [
                            _InfoRow(Icons.alarm, 'Upcoming reminders'),
                            SizedBox(height: 10),
                            _InfoRow(Icons.forum_outlined, 'Recent conversations'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: 'Conversation history',
                            icon: const Icon(Icons.history),
                            onPressed: () => _open(const FeatureStubScreen(
                              title: 'History',
                              icon: Icons.history,
                              description:
                                  'Saved conversations need the local database '
                                  'wiring for chat, which comes in a later build.',
                            )),
                          ),
                          IconButton(
                            tooltip: 'Notes',
                            icon: const Icon(Icons.sticky_note_2_outlined),
                            onPressed: () => _open(const FeatureStubScreen(
                              title: 'Notes',
                              icon: Icons.sticky_note_2_outlined,
                              description:
                                  'Local notes with search and delete confirmation '
                                  "haven't been built yet.",
                            )),
                          ),
                          IconButton(
                            tooltip: 'Reminders',
                            icon: const Icon(Icons.alarm),
                            onPressed: () => _open(const FeatureStubScreen(
                              title: 'Reminders',
                              icon: Icons.alarm,
                              description:
                                  'Reminders need notification scheduling and '
                                  "permission handling, which haven't been built yet.",
                            )),
                          ),
                          IconButton(
                            tooltip: 'Taught commands',
                            icon: const Icon(Icons.school_outlined),
                            onPressed: () => _open(TeachScreen(store: _s.store)),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () =>
                                _open(SettingsScreen(services: _s)),
                          ),
                          IconButton(
                            tooltip: 'Stop speaking',
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed:
                                _s.tts.speaking.value ? () => _s.tts.stop() : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GlassPanel(
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        radius: 28,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                  hintText: 'Type a message',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Send',
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: _send,
                            ),
                            VoiceButton(
                              speech: _s.speech,
                              onPartial: (t) {
                                _input.text = t;
                                _input.selection =
                                    TextSelection.collapsed(offset: t.length);
                              },
                              onFinal: (t) {
                                _input.text = t;
                                _send();
                              },
                              onMessage: _say,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: style?.copyWith(color: Colors.white))),
        Text('Not available yet',
            style: style?.copyWith(color: Colors.white54)),
      ],
    );
  }
}

/// Live date and time. Rebuilds itself so the rest of the screen stays still.
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;
    final h = _now.hour;
    final time = use24
        ? '${_two(h)}:${_two(_now.minute)}'
        : '${h % 12 == 0 ? 12 : h % 12}:${_two(_now.minute)} ${h < 12 ? 'AM' : 'PM'}';
    final date =
        '${_days[_now.weekday - 1]}, ${_now.day} ${_months[_now.month - 1]}';
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w300)),
        Text(date, style: text.bodySmall?.copyWith(color: Colors.white70)),
      ],
    );
  }
}
