import 'package:flutter/material.dart';

class CountdownOverlay extends StatelessWidget {
  final int count;

  const CountdownOverlay({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Text(
        '$count',
        key: ValueKey(count),
        style: const TextStyle(
          fontSize: 120,
          color: Color(0xFFFF4444),
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
