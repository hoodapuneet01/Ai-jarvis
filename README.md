# JARVIS AI (Android) - Phase 2: teachable commands

No API key and no AI model. You teach it phrases and replies; it stores them on the phone.

## What works
- Animated AI core (7 states), particles, glass UI, live date and time
- Chat: say "Jarvis, good morning" and get the reply you taught for "good morning"
- Unknown phrase: it says so and offers "Teach this"
- Taught commands screen: add, edit, delete (with confirmation), stored in on-device SQLite
- Matching ignores case, punctuation, extra spaces, and a leading "Jarvis"

## Limits (by design, not hidden)
- Exact matching only. It cannot answer questions you haven't taught it.
- Replies are text only. Actions such as "open YouTube" arrive in the app-launching phase.
- No voice, notes, reminders, history, search or documents yet (screens say "Not available yet").
- Chat messages are not saved after you leave the chat screen.

## Verification status
Phase 1 passed `flutter analyze` and `flutter test` on a real Flutter install.
Phase 2 code has not been compiled or tested by the author. Run the commands below.

## Run
```
flutter pub get
flutter analyze
flutter test
flutter run     # needs an emulator or a connected Android phone
```

## Later
Optional local model (Ollama) or OpenAI for open questions, behind the same chat screen.
