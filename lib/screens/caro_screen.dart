import 'dart:async';
import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../widgets/board_widget.dart';
import '../models/move_model.dart';

/// Màn hình chính của trò chơi Cờ Caro
class CaroScreen extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onSignOut;
  final GameMode initialMode;
  final Difficulty initialDifficulty;
  final int initialBoardSize;
  /// Thời gian giới hạn mỗi lượt (giây). null = không giới hạn.
  final int? timeLimitSeconds;

  const CaroScreen({
    super.key,
    this.userEmail,
    this.onSignOut,
    required this.initialMode,
    required this.initialDifficulty,
    required this.initialBoardSize,
    this.timeLimitSeconds,
  });

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  late final GameController _controller;

  // --- Timer state ---
  Timer? _turnTimer;
  int _secondsLeft = 0;
  Player? _lastPlayer;
  int? _lastMoveCount;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.gameMode = widget.initialMode;
    _controller.difficulty = widget.initialDifficulty;
    _controller.boardSize = widget.initialBoardSize;
    _controller.newGame();
    _lastPlayer = _controller.currentPlayer;
    _lastMoveCount = 0;
    _controller.addListener(_onControllerChanged);
    _startTimer();
  }

  /// Được gọi mỗi khi GameController notify — dùng để reset timer khi đổi lượt
  void _onControllerChanged() {
    final newMoveCount = _controller.moveHistory.length;
    if (_controller.winner == null && !_controller.isDraw) {
      final playerChanged = _controller.currentPlayer != _lastPlayer;
      final gameReset = newMoveCount == 0 && (_lastMoveCount ?? 0) != 0;
      if (playerChanged || gameReset) {
        _lastPlayer = _controller.currentPlayer;
        _startTimer();
      }
    } else {
      // Kết thúc trận — dừng đếm giờ
      _stopTimer();
    }
    _lastMoveCount = newMoveCount;
  }

  void _startTimer() {
    if (widget.timeLimitSeconds == null) return;
    _stopTimer();
    if (mounted) {
      setState(() => _secondsLeft = widget.timeLimitSeconds!);
    }
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _stopTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  String get _timerDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 10) return Colors.white;
    if (_secondsLeft > 5) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _stopTimer();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                // 1. Header: thông tin người chơi + timer + xu
                _buildHeader(),

                // 2. Bàn cờ chiếm toàn bộ không gian còn lại
                Expanded(
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: BoardWidget(
                        board: _controller.board,
                        winningLine: _controller.winningLine,
                        lastMove: _controller.lastMove,
                        onCellTap: _controller.playMove,
                      ),
                    ),
                  ),
                ),

                // 3. Footer: lượt hiện tại + nút chức năng
                _buildBottomBar(context, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header (60px) — Avatar + Tên + Badge trạng thái | Timer + Xu
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    // Badge trạng thái
    final String statusText;
    final Color statusColor;
    if (_controller.winner != null) {
      statusText = '🏆 Thắng rồi!';
      statusColor = Colors.amber;
    } else if (_controller.isDraw) {
      statusText = '🤝 Hòa cờ';
      statusColor = Colors.white60;
    } else if (_controller.isBotThinking) {
      statusText = '🤔 Bot đang nghĩ...';
      statusColor = Colors.white60;
    } else {
      statusText = '● Đến lượt';
      statusColor = Colors.greenAccent;
    }

    final String avatarText =
        (widget.userEmail?.isNotEmpty == true) ? widget.userEmail![0].toUpperCase() : 'P';
    final String playerName = widget.userEmail ?? 'Người chơi 1';

    // Xu = tổng số ván thắng × 10
    final int coins = (_controller.xWins + _controller.oWins) * 10;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF0F766E),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── Bên trái: Avatar + Tên + Badge ───
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Text(
              avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  playerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // ─── Bên phải: Timer + Xu ───
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.timeLimitSeconds != null) ...[
                // Đồng hồ đếm ngược
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, color: _timerColor, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      _timerDisplay,
                      style: TextStyle(
                        color: _timerColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              // Số xu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    '$coins xu',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar — Trạng thái lượt + Chat + Menu
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bên trái: avatar + trạng thái lượt
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: widget.userEmail != null
                    ? Text(
                        widget.userEmail![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : const Icon(Icons.person_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _controller.winner != null
                      ? 'Thắng: ${_controller.winner!.label}'
                      : (_controller.isDraw
                          ? 'Hòa cờ'
                          : 'Lượt: ${_controller.currentPlayer.label}'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Bên phải: Chat + Menu
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng Chat đang được phát triển!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _showMenuBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showMenuBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'TÙY CHỌN GAME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F766E),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.undo_rounded, color: Color(0xFF0F766E)),
                  title: const Text('Hoàn tác nước đi (Undo)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  enabled: _controller.moveHistory.isNotEmpty && !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.undo();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
                  title: const Text('Ván mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.newGame();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore_rounded,
                      color: Color(0xFFD62828)),
                  title: const Text('Khởi động lại Điểm',
                      style: TextStyle(color: Color(0xFFD62828), fontWeight: FontWeight.bold)),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.resetScore();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.arrow_back_rounded, color: Colors.blue),
                  title: const Text('Quay lại chọn chế độ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                ),
                // "Thoát trận" = đầu hàng, đối phương thắng, quay về setup
                ListTile(
                  leading: const Icon(Icons.flag_rounded, color: Colors.redAccent),
                  title: const Text('Thoát trận (Đầu hàng)',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(ctx); // đóng bottom sheet
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Xác nhận đầu hàng'),
                        content:
                            const Text('Bạn sẽ thua ván này và đối phương sẽ thắng. Tiếp tục?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text('Huỷ'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text(
                              'Đầu hàng',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      Navigator.pop(context); // quay về màn hình setup
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
