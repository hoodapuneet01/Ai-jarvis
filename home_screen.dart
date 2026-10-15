import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/core_state.dart';
import '../widgets/ai_core.dart';
import '../widgets/glass_panel.dart';
import '../widgets/particle_field.dart';
import '../widgets/status_indicator.dart';
import 'feature_stub_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController();
  Timer? _errorReset;

  // No backend exists in this build, so the honest state is offline.
  CoreState _state = CoreState.offline;

  @override
  void dispose() {
    _errorReset?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    if (_input.text.trim().isEmpty) return;
    _errorReset?.cancel();
    setState(() => _state = CoreState.error);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("The AI backend isn't connected, so this message wasn't sent."),
    ));
    _errorReset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _state = CoreState.offline);
    });
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ParticleField(color: _state.color)),
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
                          label: 'Backend not configured',
                          color: CoreState.offline.color,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final s = math.min(box.maxWidth, box.maxHeight);
                        return Center(child: AiCore(state: _state, size: s));
                      },
                    ),
                  ),
                  Text(
                    _state.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _state.color,
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
                              'Saved conversations need the AI chat and local '
                              'database, which come in later builds.',
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
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => _open(const SettingsScreen()),
                      ),
                      IconButton(
                        tooltip: 'Stop speaking',
                        icon: const Icon(Icons.stop_circle_outlined),
                        // Nothing can speak yet, so this stays disabled.
                        onPressed: null,
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
                        const IconButton(
                          tooltip: 'Microphone (not available yet)',
                          icon: Icon(Icons.mic_none),
                          onPressed: null,
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
