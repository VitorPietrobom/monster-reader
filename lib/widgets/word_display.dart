import 'package:flutter/material.dart';
import '../providers/reader_provider.dart';

class WordDisplay extends StatelessWidget {
  final String word;
  final double fontSize;

  const WordDisplay({super.key, required this.word, required this.fontSize});

  static const int _maxOrp = 3;

  // Fixed box width that holds at most _maxOrp characters.
  // Right-aligning 'before' inside this box keeps the pivot at a constant x.
  double get _boxWidth => _maxOrp * fontSize * 0.62;

  TextStyle _style(Color color, {bool bold = false}) => TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.w400,
        letterSpacing: 1.5,
        height: 1,
      );

  @override
  Widget build(BuildContext context) {
    if (word.isEmpty) return const SizedBox();

    final orp = ReaderProvider.orpIndex(word);
    final before = word.substring(0, orp);
    final pivot = word[orp];
    final after = word.substring(orp + 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tick aligned above the pivot character
        Padding(
          padding: EdgeInsets.only(left: _boxWidth + 1),
          child: _orpTick(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Fixed-width container, right-aligned — pivot always at the same x
            SizedBox(
              width: _boxWidth,
              child: Text(
                before,
                textAlign: TextAlign.right,
                maxLines: 1,
                style: _style(Colors.white),
              ),
            ),
            Text(pivot, style: _style(const Color(0xFFFF4444), bold: true)),
            Text(after, style: _style(Colors.white)),
          ],
        ),
        const SizedBox(height: 6),
        // Tick aligned below the pivot character
        Padding(
          padding: EdgeInsets.only(left: _boxWidth + 1),
          child: _orpTick(),
        ),
      ],
    );
  }

  Widget _orpTick() => Container(
        width: 2,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withOpacity(0.5),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
