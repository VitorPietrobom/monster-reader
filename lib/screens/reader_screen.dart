import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/reader_provider.dart';
import '../widgets/context_strip.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/word_display.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reader = context.read<ReaderProvider>();
      if (reader.pendingResumeIndex != null) _showResumeDialog(reader);
    });
  }

  void _showResumeDialog(ReaderProvider reader) {
    final index = reader.pendingResumeIndex!;
    final total = reader.words.length;
    final pct = (index / total * 100).round();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resume reading?'),
        content: Text(
          'You previously stopped at word $index of $total ($pct%).',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              reader.declineResume();
              Navigator.pop(context);
            },
            child: const Text('Start over',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              reader.acceptResume();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444)),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Consumer<ReaderProvider>(
          builder: (_, reader, __) {
            final mins = reader.minutesLeft;
            final timeStr = mins < 1
                ? '<1m left'
                : mins < 60
                    ? '${mins.round()}m left'
                    : '${(mins / 60).floor()}h ${(mins % 60).round()}m left';
            return Text(
              '${reader.currentIndex + 1} / ${reader.words.length}  ·  $timeStr',
              style: const TextStyle(fontSize: 13, color: Colors.white38),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ReaderProvider>(
        builder: (context, reader, _) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          return Column(
            children: [
              LinearProgressIndicator(
                value: reader.progress,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFFFF4444)),
                minHeight: 3,
              ),
              Expanded(
                child: isLandscape
                    ? _LandscapeBody(reader: reader)
                    : _PortraitBody(reader: reader),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortraitBody extends StatelessWidget {
  final ReaderProvider reader;
  const _PortraitBody({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _WordArea(reader: reader)),
        if (reader.countdown == null)
          ContextStrip(
            contextWords: reader.contextWords,
            currentIndex: reader.currentIndex,
          ),
        _FontSizeControls(reader: reader),
        _WpmSlider(reader: reader),
        _Controls(reader: reader),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  final ReaderProvider reader;
  const _LandscapeBody({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Word fills the top like a video frame.
        Expanded(child: _WordArea(reader: reader)),
        if (reader.countdown == null)
          ContextStrip(
            contextWords: reader.contextWords,
            currentIndex: reader.currentIndex,
          ),
        // Single horizontal control bar beneath, video-player style.
        _LandscapeControlBar(reader: reader),
      ],
    );
  }
}

/// Compact horizontal strip: transport | WPM slider | font-size buttons.
class _LandscapeControlBar extends StatelessWidget {
  final ReaderProvider reader;
  const _LandscapeControlBar({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          _iconBtn(Icons.restart_alt, Colors.white38, () {
            HapticFeedback.heavyImpact();
            reader.restart();
          }, size: 22),
          const SizedBox(width: 6),
          _iconBtn(Icons.skip_previous_rounded, Colors.white60, () {
            HapticFeedback.lightImpact();
            reader.stepBackward();
          }, size: 28),
          const SizedBox(width: 8),
          _playButton(reader),
          const SizedBox(width: 8),
          _iconBtn(Icons.skip_next_rounded, Colors.white60, () {
            HapticFeedback.lightImpact();
            reader.stepForward();
          }, size: 28),
          const SizedBox(width: 12),
          // WPM slider fills the middle.
          const Text('WPM',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
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
            width: 38,
            child: Text(
              '${reader.wpm}',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          // Font-size: minus / value / plus.
          _miniBtn(Icons.text_decrease_rounded, () {
            HapticFeedback.selectionClick();
            reader.setFontSize(reader.fontSize - 4);
          }),
          SizedBox(
            width: 24,
            child: Text(
              '${reader.fontSize.round()}',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ),
          _miniBtn(Icons.text_increase_rounded, () {
            HapticFeedback.selectionClick();
            reader.setFontSize(reader.fontSize + 4);
          }),
          const SizedBox(width: 8),
          _iconBtn(Icons.close, Colors.white38, () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }, size: 22),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
          {double size = 28}) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color, size: size),
      );

  Widget _miniBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.white60),
        ),
      );

  Widget _playButton(ReaderProvider reader) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          reader.togglePlayPause();
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4444),
            shape: BoxShape.circle,
          ),
          child: Icon(
            reader.isPlaying || reader.countdown != null
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
      );
}

class _WordArea extends StatelessWidget {
  final ReaderProvider reader;
  const _WordArea({required this.reader});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        reader.togglePlayPause();
      },
      behavior: HitTestBehavior.opaque,
      child: reader.countdown != null
          ? Center(child: CountdownOverlay(count: reader.countdown!))
          : LayoutBuilder(
              builder: (context, constraints) {
                // Pin WordDisplay to full width and vertically center it.
                // Using an explicit full-width SizedBox guarantees WordDisplay
                // always gets the same tight width constraint, so its internal
                // pivotColumnX never drifts between word changes.
                final lineHeight = reader.fontSize * 1.2;
                const tickStack = 14.0 + 6.0 + 6.0 + 14.0;
                final h = lineHeight + tickStack;
                final topPad = (constraints.maxHeight - h) / 2;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: topPad > 0 ? topPad : 0,
                      child: WordDisplay(
                        word: reader.currentWord,
                        fontSize: reader.fontSize,
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Aa',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 12),
          _sizeBtn(Icons.remove, () {
            HapticFeedback.selectionClick();
            reader.setFontSize(reader.fontSize - 4);
          }),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '${reader.fontSize.round()}',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
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
          const Text('WPM',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'monospace'),
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
      padding: const EdgeInsets.only(bottom: 6, top: 6),
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
            reader.isPlaying || reader.countdown != null
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
      );
}
