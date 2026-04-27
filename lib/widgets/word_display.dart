import 'package:flutter/material.dart';
import '../providers/reader_provider.dart';

/// Renders a single RSVP word with its ORP character and the two red ticks
/// pinned to a single fixed column on the screen, regardless of word length
/// or which glyph is the pivot.
///
/// Stability strategy:
///   - The widget always fills the full width given by its parent.
///   - A single `pivotColumnX` coordinate is chosen once from the parent width
///     and every subsequent layout uses exactly that x — it does NOT depend on
///     the measured width of the pivot glyph or the 'before'/'after' slices.
///   - The two ticks and the pivot glyph are all positioned so that the
///     *horizontal center* of each sits on `pivotColumnX`.
///   - 'before' is right-aligned so its last char butts up against the pivot.
///   - 'after' is left-aligned so its first char starts right after the pivot.
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
        final width = constraints.maxWidth;
        // Fixed screen column for the pivot — chosen once from parent width.
        final pivotColumnX = width * 0.42;

        final beforeWidth = _measure(before, whiteStyle, textScale);
        final pivotWidth = _measure(pivot, pivotStyle, textScale);
        final afterWidth = _measure(after, whiteStyle, textScale);

        final lineHeight = fontSize * 1.2;
        const tickHeight = 14.0;
        const tickWidth = 2.0;
        const tickGap = 6.0;
        final totalHeight =
            tickHeight + tickGap + lineHeight + tickGap + tickHeight;
        final textTop = tickHeight + tickGap;

        // Pivot glyph is centered on pivotColumnX so the red glyph's visual
        // center lines up with the ticks, no matter if it's an 'i' or an 'm'.
        final pivotLeft = pivotColumnX - pivotWidth / 2;
        final tickLeft = pivotColumnX - tickWidth / 2;

        return SizedBox(
          width: width,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top tick
              Positioned(
                left: tickLeft,
                top: 0,
                width: tickWidth,
                height: tickHeight,
                child: _orpTick(tickHeight),
              ),
              // 'before' — right edge ends exactly where the pivot glyph starts.
              Positioned(
                left: pivotLeft - beforeWidth,
                top: textTop,
                width: beforeWidth,
                child: Text(
                  before,
                  maxLines: 1,
                  softWrap: false,
                  style: whiteStyle,
                ),
              ),
              // Pivot glyph — horizontally centered on pivotColumnX.
              Positioned(
                left: pivotLeft,
                top: textTop,
                width: pivotWidth + 2,
                child: Text(
                  pivot,
                  maxLines: 1,
                  softWrap: false,
                  style: pivotStyle,
                ),
              ),
              // 'after' — starts immediately after the pivot glyph.
              Positioned(
                left: pivotLeft + pivotWidth,
                top: textTop,
                width: afterWidth + 2,
                child: Text(
                  after,
                  maxLines: 1,
                  softWrap: false,
                  style: whiteStyle,
                ),
              ),
              // Bottom tick — same column as the top tick.
              Positioned(
                left: tickLeft,
                top: textTop + lineHeight + tickGap,
                width: tickWidth,
                height: tickHeight,
                child: _orpTick(tickHeight),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orpTick(double height) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}
