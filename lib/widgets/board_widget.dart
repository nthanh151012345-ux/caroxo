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

    return Container(
      color: const Color(0xFFDCDDE4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 0.7,
          mainAxisSpacing: 0.7,
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
    );
  }
}
