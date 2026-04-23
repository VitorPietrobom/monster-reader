import 'package:flutter/material.dart';
import '../providers/reader_provider.dart';

class WordDisplay extends StatelessWidget {
  final String word;

  const WordDisplay({super.key, required this.word});

  static const double _fontSize = 52;
  static const double _charWidth = 31; // approximate width per char at fontSize 52
  static const int _maxOrp = 3;        // max ORP index = max left chars before pivot

  @override
  Widget build(BuildContext context) {
    if (word.isEmpty) return const SizedBox();

    final orp = ReaderProvider.orpIndex(word);
    final before = word.substring(0, orp);
    final pivot = word[orp];
    final after = word.substring(orp + 1);
    final leftPad = (_maxOrp - orp) * _charWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _orpTick(),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(width: leftPad),
            _wordSpan(before, Colors.white),
            _wordSpan(pivot, const Color(0xFFFF4444), bold: true),
            _wordSpan(after, Colors.white),
          ],
        ),
        const SizedBox(height: 6),
        _orpTick(),
      ],
    );
  }

  Widget _wordSpan(String text, Color color, {bool bold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _fontSize,
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.w400,
        letterSpacing: 1.5,
        height: 1,
      ),
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
