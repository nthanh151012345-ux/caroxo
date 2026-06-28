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

  const CaroScreen({
    super.key,
    this.userEmail,
    this.onSignOut,
    required this.initialMode,
    required this.initialDifficulty,
    required this.initialBoardSize,
  });

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.gameMode = widget.initialMode;
    _controller.difficulty = widget.initialDifficulty;
    _controller.boardSize = widget.initialBoardSize;
    _controller.newGame();
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

    return Scaffold(
      // Gradient nền hiện đại, chuyển dịch nhẹ nhàng từ sáng sang màu nhấn
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F766E).withValues(alpha: 0.15)
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // 1. Top bar: thông tin đối thủ
                      _buildTopBar(),

                      // 2. Khu vực bàn cờ chiếm gần toàn bộ màn hình
                      Expanded(
                        child: Container(
                          color: Colors.white, // Nền màu trắng
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

                      // 3. Thanh bottom bar màu xanh
                      _buildBottomBar(context, isDark),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Thanh trên cùng: thông tin đối thủ + nút quay lại
  Widget _buildTopBar() {
    final String opponentName;
    final Widget opponentAvatar;

    if (_controller.gameMode == GameMode.againstBot) {
      opponentName = 'Bot • ${_controller.difficulty == Difficulty.easy ? "Dễ" : "Khó"}';
      opponentAvatar = const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white24,
        child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
      );
    } else {
      opponentName = 'Người chơi 2';
      opponentAvatar = const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E),
      ),
      child: Row(
        children: [
          // Bên trái: avatar + tên đối thủ
          opponentAvatar,
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              opponentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Bên phải: nút quay lại
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  /// Xây dựng thanh bottom bar màu xanh
  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E), // Thanh bottom bar màu xanh
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bên trái: avatar người chơi
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
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
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
          // Bên phải: icon Chat, Icon Menu
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

  /// Hiển thị trình đơn Bottom Sheet khi chạm Menu
  void _showMenuBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  title: const Text('Hoàn tác nước đi (Undo)', style: TextStyle(fontWeight: FontWeight.bold)),
                  enabled: _controller.moveHistory.isNotEmpty && !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(context);
                    _controller.undo();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
                  title: const Text('Ván mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(context);
                    _controller.newGame();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFD62828)),
                  title: const Text('Khởi động lại Điểm', style: TextStyle(color: Color(0xFFD62828), fontWeight: FontWeight.bold)),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(context);
                    _controller.resetScore();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.arrow_back_rounded, color: Colors.blue),
                  title: const Text('Quay lại chọn chế độ', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
                if (widget.userEmail != null)
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.black54),
                    title: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      if (widget.onSignOut != null) {
                        widget.onSignOut!();
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
