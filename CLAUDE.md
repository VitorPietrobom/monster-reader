# CLAUDE.md — Monster Reader

Monster Reader is an Android RSVP (Rapid Serial Visual Presentation) speed-reading app built with Flutter. It displays words one at a time at a fixed focal point, using an Optimal Recognition Point (ORP) technique to eliminate eye movement. Users import text via paste, clipboard, PDF, or ePub and read it at a configurable WPM.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Dart 3.x |
| Framework | Flutter 3.24+ |
| State management | Provider (`ChangeNotifier` + `Consumer`) |
| Persistence | `shared_preferences` |
| PDF extraction | `pdfrx ^1.0.101` (pdfium-based) |
| ePub extraction | `archive ^3.6.1` (ZIP decode + HTML strip) |
| File picker | `file_picker ^8.1.2` |
| Android build | AGP 8.1.0 · Gradle 8.3 · Kotlin 1.9.0 · compileSdk 35 |
| CI | GitHub Actions → debug APK artifact |

## Project Structure

```
lib/
├── main.dart                        # App entry: init PreferencesService, theme, Provider root
├── providers/
│   └── reader_provider.dart         # SINGLE source of truth for all reader state
├── screens/
│   ├── home_screen.dart             # Text input, file import, clipboard, word count
│   └── reader_screen.dart           # RSVP display, controls, resume dialog
├── widgets/
│   ├── word_display.dart            # ORP-aligned word renderer
│   ├── context_strip.dart           # Surrounding-word context band
│   └── countdown_overlay.dart       # Animated 3-2-1 before playback
└── services/
    ├── preferences_service.dart     # SharedPreferences singleton (WPM, font, bookmark)
    ├── text_preprocessor.dart       # Cleans PDF/ePub output (page numbers, hyphens, etc.)
    └── epub_service.dart            # ePub → plain text via archive + HTML strip

android/
├── app/build.gradle                 # compileSdk 35, namespace, Kotlin options
├── build.gradle                     # AGP 8.1.0, Kotlin 1.9.0
└── gradle/wrapper/gradle-wrapper.properties  # Gradle 8.3

.github/workflows/build.yml          # CI: flutter test + flutter build apk --debug
test/widget_test.dart                # Unit tests for ReaderProvider + TextPreprocessor
```

## Critical Files — Read Before Touching

| Area | Read first |
|---|---|
| Playback / timing | `lib/providers/reader_provider.dart` |
| ORP rendering | `lib/widgets/word_display.dart` |
| File import | `lib/screens/home_screen.dart` + `lib/services/epub_service.dart` |
| Persistence | `lib/services/preferences_service.dart` |
| Android build errors | `android/app/build.gradle` + `android/build.gradle` |
| CI failures | `.github/workflows/build.yml` |

## Architecture Rules — Never Violate

1. **`ReaderProvider` is the only state owner.** Widgets read via `Consumer` or `context.read`; they never hold reader state locally.
2. **`PreferencesService` is a singleton accessed by path.** Never instantiate it directly; always use `PreferencesService.instance`.
3. **`PreferencesService.init()` must be awaited before `runApp`.** Called once in `main()`.
4. **Screens never import each other.** Navigation goes through `Navigator.push` with `MaterialPageRoute`.
5. **All file I/O (PDF, ePub) happens in `home_screen.dart` then text is handed to `ReaderProvider.loadText()`.** Services are stateless helpers, not managers.
6. **Timer management lives entirely in `ReaderProvider`.** Use the recursive `_scheduleNext()` pattern — never `Timer.periodic` (punctuation delays require variable intervals).

## Code Patterns in Use

**Reading from provider in a widget:**
```dart
Consumer<ReaderProvider>(
  builder: (context, reader, _) => Text('${reader.currentWord}'),
)
```

**Writing to provider:**
```dart
context.read<ReaderProvider>().setWpm(300);
```

**Haptic feedback conventions:**
- `mediumImpact` — play/pause, Start Reading
- `heavyImpact` — restart
- `lightImpact` — step, close, tap-to-toggle
- `selectionClick` — sliders, font size buttons

**ORP index formula** (static, in `ReaderProvider`):
```dart
static int orpIndex(String word) {
  final len = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
  if (len <= 1) return 0;
  if (len <= 5) return 1;
  if (len <= 9) return 2;
  return 3;
}
```

**Variable-delay timer (punctuation pause):**
```dart
Duration _delayForWord(String word) {
  final base = 60000.0 / _wpm;
  final last = word.isEmpty ? '' : word[word.length - 1];
  double mult = 1.0;
  if ('.!?…'.contains(last)) mult = 2.5;
  else if (',;:'.contains(last)) mult = 1.5;
  return Duration(milliseconds: (base * mult).round());
}
```

**Dart regex — multiline mode:**
```dart
// CORRECT
RegExp(r'^\s*\d+\s*$', multiLine: true)
// WRONG — Dart does not support inline (?m) flags
RegExp(r'(?m)^\s*\d+\s*$')
```

## Anti-Patterns to Avoid

| Avoid | Use instead |
|---|---|
| `Timer.periodic` for word advancement | Recursive `Timer` via `_scheduleNext()` |
| Inline `(?m)` regex flags | `RegExp(..., multiLine: true)` |
| `late SharedPreferences _prefs` | Nullable `SharedPreferences? _prefs` with null-safe defaults |
| Picking packages without checking pub.dev constraints | Verify Dart SDK constraint on pub.dev before adding |
| AGP 8+ with plugins that lack `namespace` | Ensure all plugins are actively maintained and declare namespace |
| Holding reader state in widget `State` | Put it in `ReaderProvider`, read via `Consumer` |

## Useful Commands

```bash
flutter pub get          # Install dependencies
flutter test             # Run unit tests
flutter build apk --debug   # Build debug APK
flutter build apk --release # Build release APK (requires signing config)
flutter analyze          # Static analysis
```

## Docs Index

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — system diagram, routing, DI, technical decisions
- [docs/DATA_MODEL.md](docs/DATA_MODEL.md) — all entities, persistence schema, derived fields
- [docs/PATTERNS.md](docs/PATTERNS.md) — feature template, copy-pasteable patterns, anti-patterns
- [docs/FEATURES.md](docs/FEATURES.md) — per-feature breakdown with user flows and source files
