import 'package:flutter/material.dart';

enum LessonNodeState {
  locked,
  available,
  completed,
  perfect,
}

class LessonNodeWidget extends StatelessWidget {
  final String label;
  final LessonNodeState state;
  final VoidCallback? onTap;

  const LessonNodeWidget({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(state);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: style.fill,
              shape: BoxShape.circle,
              border: Border.all(color: style.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: style.border.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(style.icon, color: style.iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.label,
            ),
          ),
        ],
      ),
    );
  }

  _LessonNodeStyle _styleFor(LessonNodeState state) {
    switch (state) {
      case LessonNodeState.locked:
        return const _LessonNodeStyle(
          fill: Color(0xFF37474F),
          border: Color(0xFF607D8B),
          iconColor: Color(0xFFB0BEC5),
          label: Color(0xFFB0BEC5),
          icon: Icons.lock_outline,
        );
      case LessonNodeState.available:
        return const _LessonNodeStyle(
          fill: Color(0xFF1565C0),
          border: Color(0xFF42A5F5),
          iconColor: Colors.white,
          label: Colors.white,
          icon: Icons.play_arrow_rounded,
        );
      case LessonNodeState.completed:
        return const _LessonNodeStyle(
          fill: Color(0xFF2E7D32),
          border: Color(0xFF81C784),
          iconColor: Colors.white,
          label: Colors.white,
          icon: Icons.check_rounded,
        );
      case LessonNodeState.perfect:
        return const _LessonNodeStyle(
          fill: Color(0xFFF9A825),
          border: Color(0xFFFFE082),
          iconColor: Colors.black,
          label: Color(0xFFFFF8E1),
          icon: Icons.star_rounded,
        );
    }
  }
}

class _LessonNodeStyle {
  final Color fill;
  final Color border;
  final Color iconColor;
  final Color label;
  final IconData icon;

  const _LessonNodeStyle({
    required this.fill,
    required this.border,
    required this.iconColor,
    required this.label,
    required this.icon,
  });
}
