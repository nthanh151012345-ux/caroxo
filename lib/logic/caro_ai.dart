import 'dart:math';
import '../models/move_model.dart';

/// Lớp tính toán nước đi của Bot AI dựa trên phương pháp Heuristic quét cửa sổ
class CaroAI {
  /// Tìm nước đi tốt nhất cho botPlayer (thường là Player.o)
  static BoardCoordinate findBestMove(
    List<List<Player?>> board,
    int boardSize,
    Player botPlayer,
    Difficulty difficulty,
  ) {
    final Player opponentPlayer = botPlayer.opponent;

    // Danh sách để chứa các ô cờ trống kèm điểm đánh giá của chúng
    final List<ScoredCoordinate> candidateMoves = [];

    // Kiểm tra xem bàn cờ có trống không (nếu là nước đi đầu tiên)
    bool isBoardEmpty = true;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != null) {
          isBoardEmpty = false;
          break;
        }
      }
      if (!isBoardEmpty) break;
    }

    // Nếu bàn cờ trống, đánh ở tâm bàn cờ
    if (isBoardEmpty) {
      return BoardCoordinate(boardSize ~/ 2, boardSize ~/ 2);
    }

    // Đánh giá điểm cho từng ô trống
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != null) continue;

        // Chỉ đánh giá các ô nằm gần nước đi đã có để tối ưu hóa hiệu năng
        // (Trong phạm vi cách các ô đã đánh tối đa 2 bước)
        if (!_hasNeighbor(board, boardSize, r, c, 2)) continue;

        final double score = _evaluateCell(board, boardSize, r, c, botPlayer, opponentPlayer);
        candidateMoves.add(ScoredCoordinate(BoardCoordinate(r, c), score));
      }
    }

    // Nếu không tìm thấy candidate nào (trường hợp cực hiếm), lấy một ô trống bất kỳ
    if (candidateMoves.isEmpty) {
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (board[r][c] == null) {
            return BoardCoordinate(r, c);
          }
        }
      }
    }

    // Sắp xếp các ứng viên theo điểm giảm dần
    candidateMoves.sort((a, b) => b.score.compareTo(a.score));

    if (difficulty == Difficulty.easy) {
      // Chế độ Dễ: 50% chọn nước tốt nhất, 50% chọn ngẫu nhiên trong top 5 nước đi tốt nhất
      final random = Random();
      if (random.nextDouble() < 0.5 && candidateMoves.length > 1) {
        final int range = min(5, candidateMoves.length);
        final int randomIndex = random.nextInt(range);
        return candidateMoves[randomIndex].coord;
      }
    }

    // Chế độ Khó hoặc chọn nước tối ưu nhất
    return candidateMoves.first.coord;
  }

  /// Kiểm tra xem ô (row, col) có ô lân cận đã được đánh trong phạm vi distance hay không
  static bool _hasNeighbor(List<List<Player?>> board, int boardSize, int row, int col, int distance) {
    for (int dr = -distance; dr <= distance; dr++) {
      for (int dc = -distance; dc <= distance; dc++) {
        if (dr == 0 && dc == 0) continue;
        final int r = row + dr;
        final int c = col + dc;
        if (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
          if (board[r][c] != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Đánh giá điểm số của việc đặt quân cờ tại ô (row, col)
  static double _evaluateCell(
    List<List<Player?>> board,
    int boardSize,
    int row,
    int col,
    Player bot,
    Player opponent,
  ) {
    double totalScore = 0.0;

    // 4 hướng cần quét
    final directions = [
      (dr: 0, dc: 1),  // Ngang
      (dr: 1, dc: 0),  // Dọc
      (dr: 1, dc: 1),  // Chéo chính
      (dr: 1, dc: -1), // Chéo phụ
    ];

    for (final dir in directions) {
      // Đối với mỗi hướng, quét qua tất cả 5 cửa sổ liên tiếp dài 5 ô chứa ô (row, col)
      for (int i = 0; i < 5; i++) {
        // Vị trí bắt đầu của cửa sổ dài 5 ô
        final int startRow = row - i * dir.dr;
        final int startCol = col - i * dir.dc;

        int countBot = 0;
        int countOpponent = 0;
        bool isWindowValid = true;

        for (int j = 0; j < 5; j++) {
          final int r = startRow + j * dir.dr;
          final int c = startCol + j * dir.dc;

          if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) {
            isWindowValid = false;
            break;
          }

          // Không đếm ô chính đang xét (vì nó đang trống và ta giả định sẽ đánh vào đây)
          if (r == row && c == col) continue;

          final val = board[r][c];
          if (val == bot) {
            countBot++;
          } else if (val == opponent) {
            countOpponent++;
          }
        }

        if (!isWindowValid) continue;

        // Điểm số theo các kịch bản
        if (countBot > 0 && countOpponent > 0) {
          // Bị hỗn hợp chặn, không thể tạo thành 5 cho bên nào
          continue;
        }

        if (countOpponent == 0) {
          // Cửa sổ tấn công của Bot
          switch (countBot) {
            case 4:
              totalScore += 100000.0; // Đánh vào thắng ngay
              break;
            case 3:
              totalScore += 10000.0;  // Tạo thành 4 nước
              break;
            case 2:
              totalScore += 500.0;   // Tạo thành 3 nước
              break;
            case 1:
              totalScore += 50.0;    // Tạo thành 2 nước
              break;
            case 0:
              totalScore += 1.0;
              break;
          }
        } else if (countBot == 0) {
          // Cửa sổ phòng thủ (chặn đối phương)
          switch (countOpponent) {
            case 4:
              totalScore += 80000.0;  // Chặn đối thủ thắng ngay
              break;
            case 3:
              totalScore += 5000.0;   // Chặn nước tạo 4 của đối thủ
              break;
            case 2:
              totalScore += 200.0;    // Chặn nước tạo 3
              break;
            case 1:
              totalScore += 20.0;
              break;
            case 0:
              totalScore += 1.0;
              break;
          }
        }
      }
    }

    // Ưu tiên nhỏ đối với các ô ở gần tâm bàn cờ để Bot ưu tiên chiếm giữ trung tâm lúc đầu game
    final double center = (boardSize - 1) / 2.0;
    final double distToCenter = sqrt(pow(row - center, 2) + pow(col - center, 2));
    final double maxDist = sqrt(2 * pow(center, 2));
    final double centerBonus = (maxDist - distToCenter) / maxDist * 2.0; // Điểm bonus tối đa +2.0 điểm
    totalScore += centerBonus;

    return totalScore;
  }
}

class ScoredCoordinate {
  final BoardCoordinate coord;
  final double score;

  ScoredCoordinate(this.coord, this.score);
}
