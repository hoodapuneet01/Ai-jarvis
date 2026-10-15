# JARVIS AI (Android) - Phase 1

Phase 1 delivers the Flutter shell and the animated interface only.

## What works in this build
- Animated AI core with 7 distinct states (idle, listening, thinking, speaking, executing, error, offline)
- Particle background, glass panels, live date and time
- Settings > Animation preview to view every state
- Sending text reports honestly that no backend is connected

## What is deliberately not built yet
Chat, speech, TTS, notes, history, reminders, app launching, web search, documents, Firebase.
Their buttons are either disabled or open a screen saying "Not available yet".
Nothing is simulated. The app requests no permissions and sends no data.

## Verification status
The code was written in an environment with no Flutter SDK and no network.
It has NOT been compiled, analyzed, or tested. Run the steps below and fix anything they surface.

## Setup
1. Install Flutter (stable, Dart >= 3.3) and the Android SDK.
2. Create the Android scaffolding, then copy this project's files over it:
   ```
   flutter create --platforms=android --project-name jarvis_ai jarvis_ai
   ```
   Copy `lib/`, `test/` and `pubspec.yaml` from this folder into the new `jarvis_ai/`, replacing the defaults.
3. From the project folder:
   ```
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```

## Next: Phase 2
FastAPI backend with OpenAI. The API key lives in a backend environment variable (`OPENAI_API_KEY`), never in the APK.
