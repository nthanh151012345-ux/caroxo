import 'package:flutter/material.dart';
import '../models/move_model.dart';

/// Bảng điểm hiển thị số trận thắng của X, O và số trận Hòa
class ScoreBoard extends StatelessWidget {
  final int xWins;
  final int oWins;
  final int draws;

  const ScoreBoard({
    super.key,
    required this.xWins,
    required this.oWins,
    required this.draws,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Điểm người chơi X
          Expanded(
            child: _ScoreItem(
              title: 'X Wins',
              score: xWins,
              color: Player.x.color,
              icon: Icons.close,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          // Số trận hòa
          Expanded(
            child: _ScoreItem(
              title: 'Draws',
              score: draws,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              icon: Icons.remove,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          // Điểm người chơi O
          Expanded(
            child: _ScoreItem(
              title: 'O Wins',
              score: oWins,
              color: Player.o.color,
              icon: Icons.panorama_fish_eye,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _ScoreItem({
    required this.title,
    required this.score,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgOpacity = isDark ? 0.15 : 0.08;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
