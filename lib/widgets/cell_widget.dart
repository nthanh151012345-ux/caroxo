import 'package:flutter/material.dart';
import '../models/move_model.dart';

/// Ô cờ trong bàn cờ Caro
class CellWidget extends StatefulWidget {
  final Player? player;
  final int row;
  final int col;
  final VoidCallback onTap;
  final bool isWinningCell;
  final bool isLastMove;

  const CellWidget({
    super.key,
    required this.player,
    required this.row,
    required this.col,
    required this.onTap,
    required this.isWinningCell,
    required this.isLastMove,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Tạo hiệu ứng scale đàn hồi khi đặt quân
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.player != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player == null && widget.player != null) {
      _controller.reset();
      _controller.forward();
    } else if (widget.player == null) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Định nghĩa màu nền cho ô cờ
    BoxDecoration decoration;
    if (widget.isWinningCell) {
      // Highlight các quân thắng bằng gradient vàng kim
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
              : [const Color(0xFFFDE68A), const Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 0.5,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.player == null ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: decoration,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vẽ nền phụ khi là nước đi cuối cùng
            if (widget.isLastMove && !widget.isWinningCell)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: (widget.player?.color ?? Colors.grey).withValues(alpha: 0.08),
                    border: Border.all(
                      color: widget.player?.color ?? Colors.grey,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            // Vẽ quân cờ (X hoặc O) kèm hiệu ứng scale đàn hồi
            ScaleTransition(
              scale: _scaleAnimation,
              child: widget.player != null
                  ? _buildPiece(widget.player!, widget.isWinningCell)
                  : const SizedBox.shrink(),
            ),
            // Chỉ báo nhỏ cho nước đi cuối cùng
            if (widget.isLastMove && widget.player != null)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isWinningCell ? Colors.white : widget.player!.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiece(Player player, bool isWinning) {
    // Kiểu chữ quân cờ có đổ bóng 3D
    return Text(
      player.label,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.0,
        color: isWinning ? Colors.white : player.color,
        shadows: [
          Shadow(
            color: (isWinning ? Colors.black : player.color).withValues(alpha: 0.25),
            offset: const Offset(1, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
