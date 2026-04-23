import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';
import '../widgets/word_display.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Consumer<ReaderProvider>(
          builder: (_, reader, __) => Text(
            '${reader.currentIndex + 1} / ${reader.words.length}',
            style: const TextStyle(fontSize: 14, color: Colors.white38),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ReaderProvider>(
        builder: (context, reader, _) {
          return Column(
            children: [
              LinearProgressIndicator(
                value: reader.progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4444)),
                minHeight: 3,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    reader.togglePlayPause();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: WordDisplay(
                      word: reader.currentWord,
                      fontSize: reader.fontSize,
                    ),
                  ),
                ),
              ),
              _FontSizeControls(reader: reader),
              _WpmSlider(reader: reader),
              _Controls(reader: reader),
            ],
          );
        },
      ),
    );
  }
}

class _FontSizeControls extends StatelessWidget {
  final ReaderProvider reader;
  const _FontSizeControls({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Aa', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 12),
          _sizeBtn(Icons.remove, () {
            HapticFeedback.selectionClick();
            reader.setFontSize(reader.fontSize - 4);
          }),
          const SizedBox(width: 8),
          Text(
            '${reader.fontSize.round()}',
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          _sizeBtn(Icons.add, () {
            HapticFeedback.selectionClick();
            reader.setFontSize(reader.fontSize + 4);
          }),
        ],
      ),
    );
  }

  Widget _sizeBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white60),
        ),
      );
}

class _WpmSlider extends StatelessWidget {
  final ReaderProvider reader;
  const _WpmSlider({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text('WPM', style: TextStyle(color: Colors.white38, fontSize: 12)),
          Expanded(
            child: Slider(
              value: reader.wpm.toDouble(),
              min: 50,
              max: 1000,
              divisions: 190,
              activeColor: const Color(0xFFFF4444),
              inactiveColor: Colors.white12,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                reader.setWpm(v.round());
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${reader.wpm}',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final ReaderProvider reader;
  const _Controls({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconBtn(Icons.restart_alt, Colors.white38, () {
            HapticFeedback.heavyImpact();
            reader.restart();
          }, size: 28),
          const SizedBox(width: 12),
          _iconBtn(Icons.skip_previous_rounded, Colors.white60, () {
            HapticFeedback.lightImpact();
            reader.stepBackward();
          }),
          const SizedBox(width: 16),
          _playButton(reader),
          const SizedBox(width: 16),
          _iconBtn(Icons.skip_next_rounded, Colors.white60, () {
            HapticFeedback.lightImpact();
            reader.stepForward();
          }),
          const SizedBox(width: 12),
          _iconBtn(Icons.close, Colors.white38, () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }, size: 28),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
          {double size = 32}) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color, size: size),
      );

  Widget _playButton(ReaderProvider reader) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          reader.togglePlayPause();
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4444),
            shape: BoxShape.circle,
          ),
          child: Icon(
            reader.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
      );
}
