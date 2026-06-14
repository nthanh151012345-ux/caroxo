import 'package:flutter/material.dart';
import '../models/move_model.dart';
import 'cell_widget.dart';

/// Bàn cờ Caro ghép từ các ô CellWidget
class BoardWidget extends StatelessWidget {
  final List<List<Player?>> board;
  final List<BoardCoordinate> winningLine;
  final BoardCoordinate? lastMove;
  final void Function(int row, int col) onCellTap;

  const BoardWidget({
    super.key,
    required this.board,
    required this.winningLine,
    required this.lastMove,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final int size = board.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: 0.8,
            mainAxisSpacing: 0.8,
          ),
          itemCount: size * size,
          itemBuilder: (context, index) {
            final row = index ~/ size;
            final col = index % size;
            final player = board[row][col];
            final coord = BoardCoordinate(row, col);
            final isWinning = winningLine.contains(coord);
            final isLast = lastMove == coord;

            return CellWidget(
              player: player,
              row: row,
              col: col,
              onTap: () => onCellTap(row, col),
              isWinningCell: isWinning,
              isLastMove: isLast,
            );
          },
        ),
      ),
    );
  }
}
