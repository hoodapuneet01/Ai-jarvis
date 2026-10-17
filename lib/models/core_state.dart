import 'package:flutter/material.dart';

/// The seven visual states of the AI core.
enum CoreState { idle, listening, thinking, speaking, executing, error, offline }

extension CoreStateX on CoreState {
  String get label => switch (this) {
        CoreState.idle => 'Idle',
        CoreState.listening => 'Listening',
        CoreState.thinking => 'Thinking',
        CoreState.speaking => 'Speaking',
        CoreState.executing => 'Executing',
        CoreState.error => 'Error',
        CoreState.offline => 'Offline',
      };

  Color get color => switch (this) {
        CoreState.idle => const Color(0xFF1E90FF),
        CoreState.listening => const Color(0xFF00E5FF),
        CoreState.thinking => const Color(0xFF5B8CFF),
        CoreState.speaking => const Color(0xFF00C8FF),
        CoreState.executing => const Color(0xFF1DE9B6),
        CoreState.error => const Color(0xFFFF4D5E),
        CoreState.offline => const Color(0xFF6B7A8F),
      };
}
