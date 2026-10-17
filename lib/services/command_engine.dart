import '../models/taught_command.dart';
import 'command_store.dart';

/// Lowercases, drops punctuation, collapses spaces, and removes a leading
/// "jarvis" so "Jarvis, Good morning!" matches "good morning".
String normalizePhrase(String input) {
  var s = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s == 'jarvis') return '';
  if (s.startsWith('jarvis ')) s = s.substring(7);
  return s;
}

/// Matches what the user says against commands they taught.
/// Exact match after normalizing. There is no guessing and no AI model.
class CommandEngine {
  CommandEngine(this.store);

  final CommandStore store;

  Future<TaughtCommand?> match(String input) async {
    final key = normalizePhrase(input);
    if (key.isEmpty) return null;
    for (final c in await store.list()) {
      if (normalizePhrase(c.phrase) == key) return c;
    }
    return null;
  }

  /// Returns an error message, or null when the command can be saved.
  Future<String?> validate(String phrase, String response,
      {int? ignoreId}) async {
    final key = normalizePhrase(phrase);
    if (key.isEmpty) return 'Enter a phrase to listen for.';
    if (response.trim().isEmpty) return 'Enter what I should reply.';
    for (final c in await store.list()) {
      if (c.id != ignoreId && normalizePhrase(c.phrase) == key) {
        return 'You already taught me that phrase. Edit it instead.';
      }
    }
    return null;
  }
}
