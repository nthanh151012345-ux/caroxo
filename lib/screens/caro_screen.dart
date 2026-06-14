import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../widgets/board_widget.dart';
import '../widgets/score_board.dart';
import '../widgets/game_status.dart';

/// Màn hình chính của trò chơi Cờ Caro
class CaroScreen extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onSignOut;

  const CaroScreen({
    super.key,
    this.userEmail,
    this.onSignOut,
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
                  final bool isTablet = constraints.maxWidth > 600;

                  return Column(
                    children: [
                      // 1. Header game
                      _buildHeader(isDark),

                      // Nội dung chính: tự động điều chỉnh dạng cột (Mobile) hoặc hàng (Tablet)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // 2. Bảng điểm (Score board)
                              ScoreBoard(
                                xWins: _controller.xWins,
                                oWins: _controller.oWins,
                                draws: _controller.draws,
                              ),
                              const SizedBox(height: 16),

                              // 3. Trạng thái Game (Status Area)
                              GameStatus(
                                currentPlayer: _controller.currentPlayer,
                                winner: _controller.winner,
                                isDraw: _controller.isDraw,
                              ),
                              const SizedBox(height: 20),

                              // 4. Bàn cờ (Game Board)
                              // Sử dụng InteractiveViewer để hỗ trợ zoom & pan trên thiết bị di động
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 600 : constraints.maxWidth,
                                  maxHeight: isTablet ? 600 : constraints.maxWidth,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    height: isTablet ? 500 : constraints.maxWidth - 32,
                                    width: isTablet ? 500 : constraints.maxWidth - 32,
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    child: InteractiveViewer(
                                      clipBehavior: Clip.hardEdge,
                                      minScale: 0.5,
                                      maxScale: 2.5,
                                      boundaryMargin: const EdgeInsets.all(50),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 520,
                                          height: 520,
                                          child: BoardWidget(
                                            board: _controller.board,
                                            winningLine: _controller.winningLine,
                                            lastMove: _controller.lastMove,
                                            onCellTap: _controller.playMove,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 5. Bảng điều khiển nút ở dưới
                              _buildBottomControls(isTablet),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
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
      margin: const EdgeInsets.all(16),
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
          // Icon Game
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
          // Tiêu đề Game
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỜ CARO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Gomoku Game 15x15',
                style: TextStyle(
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

  /// Xây dựng cụm nút điều khiển ở cuối màn hình
  Widget _buildBottomControls(bool isTablet) {
    return Row(
      children: [
        // Nút Hoàn tác (Undo)
        Expanded(
          child: _buildGradientButton(
            onPressed: _controller.moveHistory.isNotEmpty ? _controller.undo : null,
            label: 'Undo',
            icon: Icons.undo_rounded,
            gradientColors: _controller.moveHistory.isNotEmpty
                ? [const Color(0xFF64748B), const Color(0xFF475569)]
                : [const Color(0xFF94A3B8).withValues(alpha: 0.5), const Color(0xFF94A3B8).withValues(alpha: 0.5)],
          ),
        ),
        const SizedBox(width: 12),
        // Nút Ván mới (New Game)
        Expanded(
          child: _buildGradientButton(
            onPressed: _controller.newGame,
            label: 'Ván mới',
            icon: Icons.refresh_rounded,
            gradientColors: const [Color(0xFF0F766E), Color(0xFF0D9488)],
          ),
        ),
        const SizedBox(width: 12),
        // Nút Khởi động lại Điểm (Reset Score)
        Expanded(
          child: _buildGradientButton(
            onPressed: _controller.resetScore,
            label: 'Reset Điểm',
            icon: Icons.settings_backup_restore_rounded,
            gradientColors: const [Color(0xFFD62828), Color(0xFFDC2626)],
          ),
        ),
      ],
    );
  }

  /// Helper vẽ nút bấm bo tròn có hiệu ứng Gradient
  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final bool isEnabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
        icon: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white60,
          size: 18,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
