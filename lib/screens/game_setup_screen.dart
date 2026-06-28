import 'package:flutter/material.dart';
import '../models/move_model.dart';
import 'caro_screen.dart';
import 'profile_screen.dart';

class GameSetupScreen extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onSignOut;

  const GameSetupScreen({
    super.key,
    this.userEmail,
    this.onSignOut,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  GameMode _selectedMode = GameMode.againstBot;
  Difficulty _selectedDifficulty = Difficulty.easy;
  int _selectedBoardSize = 15; // default to standard 15x15

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
          child: Column(
            children: [
              // Header với nút Sign Out
              _buildHeader(isDark),

              // Vùng nội dung lựa chọn
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card Chế độ chơi
                          _buildSectionCard(
                            title: 'CHẾ ĐỘ CHƠI',
                            icon: Icons.sports_esports_rounded,
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildModeOption(
                                  mode: GameMode.againstBot,
                                  title: 'Đấu Với Máy (AI)',
                                  subtitle: 'Thử sức với trí tuệ nhân tạo thông minh',
                                  icon: Icons.smart_toy_rounded,
                                  color: const Color(0xFF14B8A6),
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),
                                _buildModeOption(
                                  mode: GameMode.twoPlayers,
                                  title: 'Đấu 2 Người',
                                  subtitle: 'Chơi cùng bạn bè trên cùng thiết bị',
                                  icon: Icons.people_alt_rounded,
                                  color: const Color(0xFF3B82F6),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Card Độ khó (chỉ hiện khi chọn Đấu với máy)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _selectedMode == GameMode.againstBot
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _buildSectionCard(
                                      title: 'ĐỘ KHÓ CỦA MÁY',
                                      icon: Icons.psychology_rounded,
                                      isDark: isDark,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildDifficultyOption(
                                              difficulty: Difficulty.easy,
                                              label: 'Dễ (Easy)',
                                              subtitle: 'Máy đánh nhẹ nhàng, có sơ hở',
                                              color: const Color(0xFF10B981),
                                              isDark: isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildDifficultyOption(
                                              difficulty: Difficulty.hard,
                                              label: 'Khó (Hard)',
                                              subtitle: 'Máy tính toán, công thủ nhạy bén',
                                              color: const Color(0xFFEF4444),
                                              isDark: isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Card Kích thước bàn cờ
                          _buildSectionCard(
                            title: 'KÍCH THƯỚC BÀN CỜ',
                            icon: Icons.grid_on_rounded,
                            isDark: isDark,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSizeOption(
                                    size: 10,
                                    label: '10 × 10',
                                    subtitle: 'Nhanh gọn',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSizeOption(
                                    size: 15,
                                    label: '15 × 15',
                                    subtitle: 'Tiêu chuẩn',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSizeOption(
                                    size: 20,
                                    label: '20 × 20',
                                    subtitle: 'Rộng rãi',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Nút Bắt đầu ván đấu
                          _buildStartButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header chứa tiêu đề và email/đăng xuất
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
          // Logo & Tên Game
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỜ CARO XO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Thiết lập trận đấu mới',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Đăng xuất và Hồ sơ nếu đã cấu hình Supabase
          if (widget.userEmail != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userEmail: widget.userEmail!,
                          onSignOut: widget.onSignOut!,
                        ),
                      ),
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.manage_accounts_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            widget.userEmail!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: widget.onSignOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
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

  /// Container bọc mỗi phân mục thiết lập (Section Card)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Lựa chọn chế độ chơi (Bot vs 2 Players)
  Widget _buildModeOption({
    required GameMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final bool isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F766E)
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF0F766E).withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0F766E),
                size: 22,
              )
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  /// Lựa chọn độ khó (Dễ / Khó)
  Widget _buildDifficultyOption({
    required Difficulty difficulty,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    final bool isSelected = _selectedDifficulty == difficulty;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lựa chọn kích thước bàn cờ (10x10, 15x15, 20x20)
  Widget _buildSizeOption({
    required int size,
    required String label,
    required String subtitle,
    required bool isDark,
  }) {
    final bool isSelected = _selectedBoardSize == size;
    final themeColor = const Color(0xFF0F766E);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBoardSize = size;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? themeColor : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? themeColor.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? themeColor : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút bấm bắt đầu với gradient và hiệu ứng shadow
  Widget _buildStartButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaroScreen(
                userEmail: widget.userEmail,
                onSignOut: widget.onSignOut,
                initialMode: _selectedMode,
                initialDifficulty: _selectedDifficulty,
                initialBoardSize: _selectedBoardSize,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'BẮT ĐẦU VÁN ĐẤU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
