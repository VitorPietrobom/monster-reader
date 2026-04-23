# Monster Reader

An Android speed-reading app built with Flutter using the **RSVP (Rapid Serial Visual Presentation)** technique. Words are displayed one at a time at a fixed point on screen, eliminating eye movement and allowing you to read significantly faster.

## Features

- **RSVP reader** — one word at a time, centered on the screen
- **ORP highlighting** — the Optimal Recognition Point letter is highlighted in red so your eye locks to a fixed position on every word
- **Adjustable WPM** — slide between 50 and 1000 words per minute, hot-swapped while playing
- **Font size control** — increase or decrease the word display size (24–80pt)
- **PDF import** — pick any text-based PDF from your device and extract its content instantly
- **Haptic feedback** — tactile response on all controls
- **Playback controls** — play/pause, step forward/backward, restart, progress bar

## Screenshots

> Coming soon.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.0 or later
- Android Studio or VS Code with the Flutter extension
- An Android device or emulator (API 21+)

### Installation

```bash
git clone https://github.com/VitorPietrobom/monster-reader.git
cd monster-reader
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                  # App entry point, theme, Provider setup
├── providers/
│   └── reader_provider.dart   # State: words, WPM, font size, timer, ORP logic
├── screens/
│   ├── home_screen.dart       # Text input and PDF import
│   └── reader_screen.dart     # RSVP player with controls
└── widgets/
    └── word_display.dart      # Word renderer with ORP alignment
```

## How RSVP Works

Traditional reading requires your eyes to scan across a line, which takes time. RSVP eliminates this by flashing words one at a time at a single fixed point. The **Optimal Recognition Point (ORP)** is a specific letter within each word — highlighted in red — that your brain uses to recognise the word fastest. By keeping that letter always at the same horizontal position, your eye never needs to move.

## PDF Support

The app uses Android's built-in PDF renderer to extract text from PDFs. Note that **image-based PDFs** (e.g. scanned documents without a text layer) cannot be read — only PDFs with actual selectable text are supported.

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `file_picker` | System file picker dialog |
| `pdf_text` | PDF text extraction |

## License

MIT
