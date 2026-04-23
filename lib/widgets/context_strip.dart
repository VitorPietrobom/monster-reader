import 'package:flutter/material.dart';

class ContextStrip extends StatelessWidget {
  final List<MapEntry<int, String>> contextWords;
  final int currentIndex;

  const ContextStrip({
    super.key,
    required this.contextWords,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Text.rich(
        TextSpan(
          children: contextWords.map((entry) {
            final isCurrent = entry.key == currentIndex;
            return TextSpan(
              text: '${entry.value} ',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isCurrent ? Colors.white : Colors.white30,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
