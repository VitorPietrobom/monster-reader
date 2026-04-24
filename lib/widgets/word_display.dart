import 'package:flutter/material.dart';
import '../providers/reader_provider.dart';

/// Renders a single RSVP word with its ORP (Optimal Recognition Point)
/// character pinned to a fixed horizontal position on screen.
///
/// Layout strategy:
///   - The widget expands to fill its parent's width.
///   - A single pivot x-coordinate is computed from the parent width.
///   - "before", pivot, and "after" slices are laid out with Stack+Positioned
///     using text measurements (not font-size guesses), so the pivot's left
///     edge always sits at the same x regardless of the word.
///   - Vertical ticks are drawn at that same x above and below the text.
class WordDisplay extends StatelessWidget {
  final String word;
  final double fontSize;

  const WordDisplay({super.key, required this.word, required this.fontSize});

  TextStyle _style(Color color, {bool bold = false}) => TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.w400,
        letterSpacing: 1.5,
        height: 1,
      );

  double _measure(String text, TextStyle style, double textScale) {
    if (text.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(textScale),
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    if (word.isEmpty) return const SizedBox();

    final orp = ReaderProvider.orpIndex(word);
    final before = word.substring(0, orp);
    final pivot = word[orp];
    final after = word.substring(orp + 1);

    final whiteStyle = _style(Colors.white);
    final pivotStyle = _style(const Color(0xFFFF4444), bold: true);

    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fixed pivot x — a bit left of center feels natural in RSVP apps
        // because most words have more characters after the ORP than before.
        final pivotX = constraints.maxWidth * 0.42;

        final beforeWidth = _measure(before, whiteStyle, textScale);
        final pivotWidth = _measure(pivot, pivotStyle, textScale);
        final afterWidth = _measure(after, whiteStyle, textScale);

        final lineHeight = fontSize * 1.2;
        const tickHeight = 14.0;
        const tickGap = 6.0;
        final totalHeight = tickHeight + tickGap + lineHeight + tickGap + tickHeight;

        final textTop = tickHeight + tickGap;

        return SizedBox(
          width: constraints.maxWidth,
          height: totalHeight,
          child: Stack(
            children: [
              // Top tick — its left edge sits at pivotX so the tick sits
              // directly above the pivot glyph.
              Positioned(
                left: pivotX,
                top: 0,
                child: _orpTick(),
              ),
              // 'before' — right edge ends exactly at pivotX.
              Positioned(
                left: pivotX - beforeWidth,
                top: textTop,
                width: beforeWidth,
                child: Text(
                  before,
                  maxLines: 1,
                  softWrap: false,
                  style: whiteStyle,
                ),
              ),
              // Pivot character — left edge starts exactly at pivotX.
              Positioned(
                left: pivotX,
                top: textTop,
                width: pivotWidth + 2,
                child: Text(
                  pivot,
                  maxLines: 1,
                  softWrap: false,
                  style: pivotStyle,
                ),
              ),
              // 'after' — starts right after the pivot.
              Positioned(
                left: pivotX + pivotWidth,
                top: textTop,
                width: afterWidth + 2,
                child: Text(
                  after,
                  maxLines: 1,
                  softWrap: false,
                  style: whiteStyle,
                ),
              ),
              // Bottom tick — same x as the top tick.
              Positioned(
                left: pivotX,
                top: textTop + lineHeight + tickGap,
                child: _orpTick(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orpTick() => Container(
        width: 2,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
