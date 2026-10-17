import 'package:flutter/material.dart';

import '../config.dart';
import '../models/core_state.dart';
import '../services/app_services.dart';
import '../widgets/ai_core.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.blur_circular),
              title: const Text('Animation preview'),
              subtitle: const Text('See each state of the AI core'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CorePreviewScreen()),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: const Text('Speak replies aloud'),
              value: settings.speakReplies,
              onChanged: settings.setSpeakReplies,
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Speech rate'),
              subtitle: Slider(
                value: settings.speechRate,
                min: 0.2,
                max: 1.0,
                divisions: 8,
                label: settings.speechRate.toStringAsFixed(1),
                onChanged: settings.setSpeechRate,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Test voice'),
              subtitle: const Text('Speak a sample sentence'),
              onTap: () async {
                final problem = await services.tts.speak(
                  'Hello, I am $kAssistantName.',
                  rate: settings.speechRate,
                );
                if (problem != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(problem)));
                }
              },
            ),
            const ListTile(
              leading: Icon(Icons.mic_none),
              title: Text('Microphone'),
              subtitle: Text(
                "Used only while you've tapped the microphone. The app doesn't "
                "record or save audio. Voice input uses your phone's speech "
                'service, which may send audio to its provider (usually Google).',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.hearing_disabled_outlined),
              title: Text('Wake word'),
              subtitle: Text(
                "Not available. Android doesn't let normal apps listen in the "
                'background, so tap the microphone to talk.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('AI model'),
              subtitle: Text(
                'None connected. Replies come only from commands you taught. '
                'Open questions need a model, which can be added later.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Privacy'),
              subtitle: Text(
                'Taught commands are stored on this phone only.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CorePreviewScreen extends StatefulWidget {
  const CorePreviewScreen({super.key});

  @override
  State<CorePreviewScreen> createState() => _CorePreviewScreenState();
}

class _CorePreviewScreenState extends State<CorePreviewScreen> {
  CoreState _state = CoreState.idle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animation preview')),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final s = box.maxWidth < box.maxHeight ? box.maxWidth : box.maxHeight;
                return Center(child: AiCore(state: _state, size: s));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final s in CoreState.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _state == s,
                    onSelected: (_) => setState(() => _state = s),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Preview only. This doesn't reflect real assistant activity.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
