import 'package:flutter/material.dart';
import '../models/move_model.dart';

/// Hiển thị trạng thái lượt đi hiện tại hoặc kết quả ván đấu
class GameStatus extends StatelessWidget {
  final Player currentPlayer;
  final Player? winner;
  final bool isDraw;
  final bool isBotThinking;

  const GameStatus({
    super.key,
    required this.currentPlayer,
    required this.winner,
    required this.isDraw,
    this.isBotThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Xác định nội dung, màu sắc, icon tương ứng với từng trạng thái
    final String statusText;
    final Color mainColor;
    final IconData iconData;
    final Key widgetKey;

    if (winner != null) {
      statusText = '${winner!.label} CHIẾN THẮNG!';
      mainColor = winner!.color;
      iconData = Icons.emoji_events_rounded;
      widgetKey = ValueKey('win_${winner!.name}');
    } else if (isDraw) {
      statusText = 'HÒA CỜ!';
      mainColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      iconData = Icons.handshake_rounded;
      widgetKey = const ValueKey('draw');
    } else if (isBotThinking) {
      statusText = 'Máy đang suy nghĩ...';
      mainColor = const Color(0xFF0F766E);
      iconData = Icons.psychology_rounded;
      widgetKey = const ValueKey('bot_thinking');
    } else {
      statusText = 'Lượt của: ${currentPlayer.label}';
      mainColor = currentPlayer.color;
      iconData = Icons.play_arrow_rounded;
      widgetKey = ValueKey('turn_${currentPlayer.name}');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Kết hợp hiệu ứng Fade và Scale nhẹ khi trạng thái thay đổi
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        key: widgetKey,
        decoration: BoxDecoration(
          color: mainColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: mainColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: winner != null
              ? [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon động với animation xoay nhẹ nếu chiến thắng
            _buildStatusIcon(iconData, mainColor, winner != null),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: mainColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color, bool isWinner) {
    final iconWidget = Icon(
      icon,
      color: color,
      size: 26,
    );

    if (isWinner) {
      // Icon cup nhấp nháy/phóng to thu nhỏ nhẹ cho người thắng cuộc
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.2),
        duration: const Duration(milliseconds: 600),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        onEnd: () {}, // loop có thể dùng State, nhưng chuyển động tĩnh vừa phải cho chuyên nghiệp
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
