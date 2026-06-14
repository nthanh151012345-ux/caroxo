import 'package:flutter/material.dart';

/// Đại diện cho người chơi (X hoặc O)
enum Player {
  x('X', Color(0xFF2563EB)), // X: màu xanh
  o('O', Color(0xFFD62828)); // O: màu đỏ

  const Player(this.label, this.color);

  final String label;
  final Color color;

  /// Lấy đối thủ của người chơi hiện tại
  Player get opponent => this == Player.x ? Player.o : Player.x;
}

/// Tọa độ ô cờ (hàng, cột) để so sánh và highlight nước đi thắng cuộc
class BoardCoordinate {
  final int row;
  final int col;

  const BoardCoordinate(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCoordinate &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

/// Lưu trữ thông tin một nước đi
class BoardMove {
  final int row;
  final int col;
  final Player player;
  final int moveNumber;

  const BoardMove({
    required this.row,
    required this.col,
    required this.player,
    required this.moveNumber,
  });
}

/// Chế độ chơi của game Caro
enum GameMode {
  twoPlayers, // 2 người chơi trên cùng máy
  againstBot,  // Chơi với máy (AI)
}

/// Độ khó của Bot (AI)
enum Difficulty {
  easy, // Dễ
  hard, // Khó
}
