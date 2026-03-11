import 'package:flutter/material.dart';

class HeartsDisplay extends StatelessWidget {
  final int hearts;
  final int maxHearts;

  const HeartsDisplay({
    super.key,
    required this.hearts,
    this.maxHearts = 5,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = maxHearts <= 0 ? 1 : maxHearts;
    final safeHearts = hearts.clamp(0, safeMax);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(safeMax, (index) {
        final filled = index < safeHearts;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: filled ? const Color(0xFFE53935) : Colors.white38,
          ),
        );
      }),
    );
  }
}
