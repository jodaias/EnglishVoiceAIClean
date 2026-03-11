import 'package:flutter/material.dart';

class FeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final VoidCallback? onContinue;

  const FeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.message,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1 + (0.15 * value)),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: color.withOpacity(0.65 + (0.25 * value))),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct' : 'Try again',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
