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
                      // 1. Header game
                      _buildHeader(isDark),

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

  /// Widget vẽ Header của Game kèm thông tin tài khoản nếu có
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Game / Nút quay lại
          if (Navigator.canPop(context)) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_4x4_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
          ],
          // Tiêu đề Game
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CỜ CARO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                _controller.gameMode == GameMode.againstBot
                    ? 'Đấu với máy - ${_controller.difficulty == Difficulty.easy ? "Dễ" : "Khó"} (${_controller.boardSize}x${_controller.boardSize})'
                    : 'Đấu 2 người (${_controller.boardSize}x${_controller.boardSize})',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Hiển thị email và nút Logout nếu được cấu hình Supabase
          if (widget.userEmail != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    widget.userEmail!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: widget.onSignOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
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
