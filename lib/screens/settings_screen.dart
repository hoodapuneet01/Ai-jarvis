import 'package:flutter/material.dart';

import '../models/core_state.dart';
import '../widgets/ai_core.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
          const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('AI backend'),
            subtitle: Text(
              'Not configured. Chat arrives in the next build and needs an '
              'OpenAI API key stored on the backend, never in the app.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text(
              "This build doesn't record audio, request permissions, or send "
              'data anywhere.',
            ),
          ),
        ],
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
