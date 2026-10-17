import 'package:flutter/material.dart';

import '../models/taught_command.dart';
import '../services/command_engine.dart';
import '../services/command_store.dart';

/// Opens the teach/edit dialog. Returns true when a command was saved.
Future<bool> showTeachDialog(
  BuildContext context,
  CommandStore store, {
  TaughtCommand? existing,
  String? phrase,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _TeachDialog(store: store, existing: existing, phrase: phrase),
  );
  return saved ?? false;
}

class TeachScreen extends StatefulWidget {
  const TeachScreen({super.key, required this.store});

  final CommandStore store;

  @override
  State<TeachScreen> createState() => _TeachScreenState();
}

class _TeachScreenState extends State<TeachScreen> {
  List<TaughtCommand>? _commands;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.store.list();
      if (!mounted) return;
      setState(() {
        _commands = list;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _teach([TaughtCommand? existing]) async {
    final saved = await showTeachDialog(context, widget.store, existing: existing);
    if (saved) _load();
  }

  Future<void> _delete(TaughtCommand c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this command?'),
        content: Text('I will stop replying to "${c.phrase}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.store.delete(c.id!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70);
    Widget body;
    if (_error != null) {
      body = Center(child: Text("Couldn't load commands: $_error", style: muted));
    } else if (_commands == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_commands!.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No commands yet. Tap Teach to add your first one.',
            textAlign: TextAlign.center,
            style: muted,
          ),
        ),
      );
    } else {
      body = ListView(
        children: [
          for (final c in _commands!)
            ListTile(
              title: Text(c.phrase),
              subtitle: Text(c.response, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _teach(c),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(c),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Taught commands')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Teach',
        onPressed: () => _teach(),
        icon: const Icon(Icons.add),
        label: const Text('Teach'),
      ),
    );
  }
}

class _TeachDialog extends StatefulWidget {
  const _TeachDialog({required this.store, this.existing, this.phrase});

  final CommandStore store;
  final TaughtCommand? existing;
  final String? phrase;

  @override
  State<_TeachDialog> createState() => _TeachDialogState();
}

class _TeachDialogState extends State<_TeachDialog> {
  late final TextEditingController _phrase = TextEditingController(
      text: widget.existing?.phrase ?? widget.phrase ?? '');
  late final TextEditingController _response =
      TextEditingController(text: widget.existing?.response ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _phrase.dispose();
    _response.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final err = await CommandEngine(widget.store).validate(
        _phrase.text,
        _response.text,
        ignoreId: widget.existing?.id,
      );
      if (err != null) {
        if (!mounted) return;
        setState(() {
          _error = err;
          _saving = false;
        });
        return;
      }
      final phrase = _phrase.text.trim();
      final response = _response.text.trim();
      if (widget.existing == null) {
        await widget.store.add(phrase, response);
      } else {
        await widget.store
            .update(widget.existing!.copyWith(phrase: phrase, response: response));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't save: $e";
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Teach a command' : 'Edit command'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('phrase'),
              controller: _phrase,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'When I say'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('response'),
              controller: _response,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reply with'),
            ),
            const SizedBox(height: 12),
            Text(
              "Stored as plain text on this phone. Don't teach passwords or secrets.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white54),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        TextButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
