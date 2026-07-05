import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/game_controller.dart';
import '../models/move_model.dart';
import '../widgets/board_widget.dart';

class CaroScreen extends StatefulWidget {
  final String? userEmail;
  final VoidCallback? onSignOut;
  final GameMode initialMode;
  final Difficulty initialDifficulty;
  final int initialBoardSize;
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
      _stopTimer();
    }
    _lastMoveCount = newMoveCount;
  }

  void _startTimer() {
    if (widget.timeLimitSeconds == null) {
      return;
    }
    _stopTimer();
    if (mounted) {
      setState(() => _secondsLeft = widget.timeLimitSeconds!);
    }
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 10) {
      return Colors.white;
    }
    if (_secondsLeft > 5) {
      return Colors.orangeAccent;
    }
    return Colors.redAccent;
  }

  String get _displayName {
    final raw = widget.userEmail?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Player';
    }
    final localPart = raw.split('@').first;
    if (localPart.isEmpty) {
      return raw;
    }
    return localPart[0].toUpperCase() + localPart.substring(1);
  }

  String get _opponentName {
    return widget.initialMode == GameMode.againstBot ? 'Bot' : 'Opponent';
  }

  String get _localAvatarText {
    return widget.userEmail?.isNotEmpty == true
        ? widget.userEmail![0].toUpperCase()
        : 'P';
  }

  String get _opponentAvatarText {
    return widget.initialMode == GameMode.againstBot ? 'B' : 'O';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              children: [
                _buildHeader(),
                _buildBoardViewport(),
                _buildBottomBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      key: const ValueKey('game_header_bar'),
      height: 58,
      child: _buildPlayerBar(
        key: const ValueKey('opponent_player_bar'),
        player: Player.o,
        name: _opponentName,
        avatarText: _opponentAvatarText,
        avatarColor: const Color(0xFF1D73A7),
        showActions: false,
      ),
    );
  }

  Widget _buildBoardViewport() {
    return Expanded(
      child: Container(
        key: const ValueKey('game_board_viewport'),
        color: const Color(0xFFF7F7FB),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = _controller.board.length;
            final cellSize = (constraints.maxHeight / boardSize).clamp(
              24.0,
              32.0,
            );
            final side = cellSize * boardSize;
            final isDesktopWide = constraints.maxWidth >= 700;
            final canvasWidth = constraints.maxWidth > side
                ? constraints.maxWidth
                : side;
            final canvasHeight = isDesktopWide && constraints.maxHeight > side
                ? constraints.maxHeight
                : side;

            return InteractiveViewer(
              constrained: false,
              minScale: 0.8,
              maxScale: 2.4,
              boundaryMargin: const EdgeInsets.all(96),
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Center(
                  child: SizedBox.square(
                    key: const ValueKey('game_board_surface'),
                    dimension: side,
                    child: BoardWidget(
                      board: _controller.board,
                      winningLine: _controller.winningLine,
                      lastMove: _controller.lastMove,
                      onCellTap: _controller.playMove,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SizedBox(
      key: const ValueKey('game_bottom_bar'),
      height: 58,
      child: _buildPlayerBar(
        key: const ValueKey('local_player_bar'),
        player: Player.x,
        name: _displayName,
        avatarText: _localAvatarText,
        avatarColor: const Color(0xFFE85C8B),
        showActions: true,
        actionsContext: context,
      ),
    );
  }

  Widget _buildPlayerBar({
    required Key key,
    required Player player,
    required String name,
    required String avatarText,
    required Color avatarColor,
    required bool showActions,
    BuildContext? actionsContext,
  }) {
    final isActive =
        _controller.currentPlayer == player &&
        _controller.winner == null &&
        !_controller.isDraw;
    final status = _barStatusFor(player);
    final coins =
        1000 +
        (player == Player.x ? _controller.xWins : _controller.oWins) * 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final showCoins = !(showActions && isCompact);
        final showActionButtons = showActions && !isCompact;
        final statusInTrailing = showActions && isCompact;

        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: const Color(0xFF28B7E5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: avatarColor,
                      child: Text(
                        avatarText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.label,
                      style: TextStyle(
                        color: player.color,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (status != null && !statusInTrailing) ...[
                      const SizedBox(width: 10),
                      _TurnBadge(text: status.text, color: status.color),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status != null && statusInTrailing) ...[
                    _TurnBadge(text: status.text, color: status.color),
                    const SizedBox(width: 8),
                  ],
                  if (isActive && widget.timeLimitSeconds != null) ...[
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      color: _timerColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _timerDisplay,
                      style: TextStyle(
                        color: _timerColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (showCoins) ...[
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  if (showActionButtons && actionsContext != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Chat',
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(actionsContext).showSnackBar(
                          const SnackBar(
                            content: Text('Chat dang duoc phat trien!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Menu',
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => _showMenuBottomSheet(actionsContext),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  _BarStatus? _barStatusFor(Player player) {
    if (_controller.winner != null) {
      return _BarStatus(
        text: _controller.winner == player ? 'Winner' : 'Lost',
        color: _controller.winner == player ? Colors.amber : Colors.white70,
      );
    }
    if (_controller.isDraw) {
      return const _BarStatus(text: 'Draw', color: Colors.white70);
    }
    if (_controller.currentPlayer != player) {
      return null;
    }
    if (_controller.isBotThinking && player == Player.o) {
      return const _BarStatus(text: 'Thinking', color: Colors.white70);
    }
    return _BarStatus(
      text: player == Player.x ? 'Your Turn' : 'Opponent Turn',
      color: const Color(0xFF63D34E),
    );
  }

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
                  'TUY CHON GAME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF28B7E5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.undo_rounded,
                    color: Color(0xFF28B7E5),
                  ),
                  title: const Text(
                    'Hoan tac nuoc di',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  enabled:
                      _controller.moveHistory.isNotEmpty &&
                      !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.undo();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF28B7E5),
                  ),
                  title: const Text(
                    'Van moi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.newGame();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.settings_backup_restore_rounded,
                    color: Color(0xFFD62828),
                  ),
                  title: const Text(
                    'Khoi dong lai diem',
                    style: TextStyle(
                      color: Color(0xFFD62828),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  enabled: !_controller.isBotThinking,
                  onTap: () {
                    Navigator.pop(ctx);
                    _controller.resetScore();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'Quay lai chon che do',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.flag_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Thoat tran',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Xac nhan dau hang'),
                        content: const Text('Ban se thua van nay. Tiep tuc?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text('Huy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text(
                              'Dau hang',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      Navigator.pop(context);
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

class _TurnBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _TurnBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BarStatus {
  final String text;
  final Color color;

  const _BarStatus({required this.text, required this.color});
}
