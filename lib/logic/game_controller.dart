import 'package:flutter/material.dart';
import '../models/move_model.dart';
import 'sound_manager.dart';
import 'caro_ai.dart';

/// Bộ điều khiển logic chính của game Caro (Gomoku)
class GameController extends ChangeNotifier {
  static const int boardSize = 20;

  /// Bàn cờ 20x20 chứa thông tin các quân cờ đã đánh
  late List<List<Player?>> board;

  /// Lịch sử các nước đi để phục vụ chức năng Undo
  final List<BoardMove> moveHistory = [];

  /// Người chơi hiện tại (mặc định X đi trước)
  Player currentPlayer = Player.x;

  /// Người chiến thắng (nếu có)
  Player? winner;

  /// Tọa độ của các quân cờ thắng cuộc để highlight
  List<BoardCoordinate> winningLine = [];

  /// Trạng thái hòa cờ
  bool isDraw = false;

  /// Nước đi cuối cùng vừa thực hiện
  BoardCoordinate? lastMove;

  /// Điểm số của người chơi và hòa
  int xWins = 0;
  int oWins = 0;
  int draws = 0;

  /// Chế độ chơi hiện tại
  GameMode gameMode = GameMode.twoPlayers;

  /// Độ khó của máy hiện tại
  Difficulty difficulty = Difficulty.easy;

  /// Trạng thái máy đang suy nghĩ
  bool isBotThinking = false;

  GameController() {
    _initBoard();
  }

  /// Khởi tạo hoặc xóa bàn cờ
  void _initBoard() {
    board = List.generate(
      boardSize,
      (_) => List<Player?>.filled(boardSize, null),
    );
  }

  /// Thực hiện nước đi tại vị trí (row, col) - Được gọi từ UI
  void playMove(int row, int col) {
    // Nếu ô đã được đánh, game đã kết thúc hoặc máy đang suy nghĩ thì không làm gì
    if (board[row][col] != null || winner != null || isDraw || isBotThinking) {
      return;
    }

    // Nếu ở chế độ đấu với máy, chỉ cho phép người chơi đánh ở lượt của X
    if (gameMode == GameMode.againstBot && currentPlayer != Player.x) {
      return;
    }

    _executeMove(row, col);
  }

  /// Logic thực thi một nước đi và kiểm tra trạng thái game
  void _executeMove(int row, int col) {
    board[row][col] = currentPlayer;
    final move = BoardMove(
      row: row,
      col: col,
      player: currentPlayer,
      moveNumber: moveHistory.length + 1,
    );
    moveHistory.add(move);
    lastMove = BoardCoordinate(row, col);

    // Kiểm tra thắng thua
    final winLine = _getWinningLine(row, col, currentPlayer);
    if (winLine.isNotEmpty) {
      winner = currentPlayer;
      winningLine = winLine;
      if (currentPlayer == Player.x) {
        xWins++;
      } else {
        oWins++;
      }
      SoundManager.playWin();
    } else if (moveHistory.length == boardSize * boardSize) {
      isDraw = true;
      draws++;
      SoundManager.playDraw();
    } else {
      // Đổi lượt đi
      currentPlayer = currentPlayer.opponent;
      SoundManager.playMove();

      // Nếu là chế độ chơi với máy và tới lượt của Bot (O)
      if (gameMode == GameMode.againstBot && currentPlayer == Player.o && winner == null && !isDraw) {
        isBotThinking = true;
        notifyListeners();

        // Máy suy nghĩ và đánh sau 500ms
        Future.delayed(const Duration(milliseconds: 500), () {
          // Kiểm tra lại các điều kiện trước khi đánh để tránh lỗi do click nhanh/undo
          if (winner == null && !isDraw && currentPlayer == Player.o && gameMode == GameMode.againstBot) {
            isBotThinking = false;
            final botMove = CaroAI.findBestMove(board, boardSize, Player.o, difficulty);
            _executeMove(botMove.row, botMove.col);
          } else {
            isBotThinking = false;
            notifyListeners();
          }
        });
      }
    }

    notifyListeners();
  }

  /// Hoàn tác nước đi (Undo)
  void undo() {
    if (moveHistory.isEmpty || isBotThinking) return;

    _undoSingleMove();

    // Nếu chơi với máy và lượt tiếp theo là của máy (tức là ta vừa undo nước đi của người chơi X,
    // quay về lượt O của máy), ta cần undo thêm 1 nước nữa để đưa về lượt của người chơi X.
    if (gameMode == GameMode.againstBot && currentPlayer == Player.o && moveHistory.isNotEmpty) {
      _undoSingleMove();
    }

    notifyListeners();
  }

  /// Thực hiện rút lại 1 nước đi đơn lẻ
  void _undoSingleMove() {
    if (moveHistory.isEmpty) return;

    // Nếu game đã kết thúc trước đó, cần thu hồi kết quả điểm số
    if (winner != null) {
      if (winner == Player.x) {
        xWins = (xWins > 0) ? xWins - 1 : 0;
      } else {
        oWins = (oWins > 0) ? oWins - 1 : 0;
      }
      winner = null;
      winningLine = [];
    } else if (isDraw) {
      draws = (draws > 0) ? draws - 1 : 0;
      isDraw = false;
    }

    // Xóa nước đi cuối cùng
    final last = moveHistory.removeLast();
    board[last.row][last.col] = null;

    // Cập nhật lại nước đi cuối cùng để highlight
    if (moveHistory.isNotEmpty) {
      final prev = moveHistory.last;
      lastMove = BoardCoordinate(prev.row, prev.col);
    } else {
      lastMove = null;
    }

    // Trả lại lượt đi cho người vừa bị hoàn tác
    currentPlayer = last.player;
  }

  /// Chơi ván mới (Giữ nguyên điểm số)
  void newGame({GameMode? mode, Difficulty? diff}) {
    if (mode != null) gameMode = mode;
    if (diff != null) difficulty = diff;

    _initBoard();
    moveHistory.clear();
    currentPlayer = Player.x;
    winner = null;
    winningLine = [];
    isDraw = false;
    lastMove = null;
    isBotThinking = false;
    notifyListeners();
  }

  /// Làm mới điểm số và chơi ván mới
  void resetScore({GameMode? mode, Difficulty? diff}) {
    xWins = 0;
    oWins = 0;
    draws = 0;
    newGame(mode: mode, diff: diff);
  }

  /// Thuật toán kiểm tra thắng cuộc tối ưu O(1) từ vị trí đánh mới nhất
  List<BoardCoordinate> _getWinningLine(int row, int col, Player player) {
    // 4 hướng quét: Ngang, Dọc, Chéo chính, Chéo phụ
    final directions = [
      (dr: 0, dc: 1),   // Hàng ngang
      (dr: 1, dc: 0),   // Hàng dọc
      (dr: 1, dc: 1),   // Đường chéo chính
      (dr: 1, dc: -1),  // Đường chéo phụ
    ];

    for (final dir in directions) {
      final line = <BoardCoordinate>[BoardCoordinate(row, col)];

      // Quét theo chiều xuôi (dr, dc)
      int r = row + dir.dr;
      int c = col + dir.dc;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == player) {
        line.add(BoardCoordinate(r, c));
        r += dir.dr;
        c += dir.dc;
      }

      // Quét theo chiều ngược (-dr, -dc)
      r = row - dir.dr;
      c = col - dir.dc;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == player) {
        line.add(BoardCoordinate(r, c));
        r -= dir.dr;
        c -= dir.dc;
      }

      // Luật Caro chuẩn: 5 quân liên tiếp cùng loại trở lên
      if (line.length >= 5) {
        return line;
      }
    }

    return const [];
  }
}
