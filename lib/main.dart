import 'package:flutter/material.dart';

import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(const CaroApp());
}

class CaroApp extends StatelessWidget {
  const CaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caro XO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userEmail = SupabaseConfig.client?.auth.currentUser?.email;
  }

  void _handleSignedIn(String email) {
    setState(() {
      _userEmail = email;
    });
  }

  Future<void> _handleSignOut() async {
    await SupabaseConfig.client?.auth.signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      _userEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || _userEmail == null) {
      return LoginPage(onSignedIn: _handleSignedIn);
    }

    return CaroGamePage(userEmail: _userEmail!, onSignOut: _handleSignOut);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSignedIn});

  final ValueChanged<String> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _errorMessage = 'Thieu SUPABASE_URL hoac SUPABASE_ANON_KEY.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseConfig.client!.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final email = response.user?.email;

      if (email == null || email.isEmpty) {
        throw Exception('Khong lay duoc email nguoi dung.');
      }

      widget.onSignedIn(email);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on, color: colorScheme.primary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Caro XO',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Nhap email.';
                        }
                        if (!email.contains('@')) {
                          return 'Email khong hop le.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Hien password'
                              : 'An password',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhap password.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _signIn,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Dang nhap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CaroGamePage extends StatefulWidget {
  const CaroGamePage({
    super.key,
    required this.userEmail,
    required this.onSignOut,
  });

  final String userEmail;
  final VoidCallback onSignOut;

  @override
  State<CaroGamePage> createState() => _CaroGamePageState();
}

class _CaroGamePageState extends State<CaroGamePage> {
  static const int boardSize = 15;
  static const int winLength = 5;

  late List<List<Player?>> _board;
  Player _currentPlayer = Player.x;
  Player? _winner;
  bool _isDraw = false;
  int _moveCount = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _board = List.generate(
      boardSize,
      (_) => List<Player?>.filled(boardSize, null),
    );
    _currentPlayer = Player.x;
    _winner = null;
    _isDraw = false;
    _moveCount = 0;
    setState(() {});
  }

  void _playMove(int row, int col) {
    if (_board[row][col] != null || _winner != null || _isDraw) {
      return;
    }

    setState(() {
      _board[row][col] = _currentPlayer;
      _moveCount++;

      if (_hasWon(row, col, _currentPlayer)) {
        _winner = _currentPlayer;
      } else if (_moveCount == boardSize * boardSize) {
        _isDraw = true;
      } else {
        _currentPlayer = _currentPlayer == Player.x ? Player.o : Player.x;
      }
    });
  }

  bool _hasWon(int row, int col, Player player) {
    const directions = [
      (rowStep: 0, colStep: 1),
      (rowStep: 1, colStep: 0),
      (rowStep: 1, colStep: 1),
      (rowStep: 1, colStep: -1),
    ];

    for (final direction in directions) {
      final total =
          1 +
          _countPieces(row, col, direction.rowStep, direction.colStep, player) +
          _countPieces(
            row,
            col,
            -direction.rowStep,
            -direction.colStep,
            player,
          );

      if (total >= winLength) {
        return true;
      }
    }

    return false;
  }

  int _countPieces(int row, int col, int rowStep, int colStep, Player player) {
    var count = 0;
    var nextRow = row + rowStep;
    var nextCol = col + colStep;

    while (_isInsideBoard(nextRow, nextCol) &&
        _board[nextRow][nextCol] == player) {
      count++;
      nextRow += rowStep;
      nextCol += colStep;
    }

    return count;
  }

  bool _isInsideBoard(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  String get _statusText {
    if (_winner != null) {
      return '${_winner!.label} thang';
    }

    if (_isDraw) {
      return 'Hoa';
    }

    return 'Luot ${_currentPlayer.label}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EA),
      appBar: AppBar(
        title: const Text('Caro XO'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    widget.userEmail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Dang xuat',
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _GameHeader(
                      statusText: _statusText,
                      currentPlayer: _winner == null && !_isDraw
                          ? _currentPlayer
                          : _winner,
                      onReset: _resetGame,
                    ),
                    const SizedBox(height: 10),
                    const _SupabaseStatus(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                            maxHeight: constraints.maxHeight,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFCF0),
                                border: Border.all(
                                  color: const Color(0xFF263238),
                                  width: 2,
                                ),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: boardSize,
                                    ),
                                itemCount: boardSize * boardSize,
                                itemBuilder: (context, index) {
                                  final row = index ~/ boardSize;
                                  final col = index % boardSize;
                                  final player = _board[row][col];

                                  return _BoardCell(
                                    player: player,
                                    onTap: () => _playMove(row, col),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.statusText,
    required this.currentPlayer,
    required this.onReset,
  });

  final String statusText;
  final Player? currentPlayer;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final playerColor = currentPlayer?.color ?? const Color(0xFF263238);

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4DCCB)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.sports_esports, color: playerColor),
                  const SizedBox(width: 10),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: playerColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Choi lai'),
        ),
      ],
    );
  }
}

class _SupabaseStatus extends StatelessWidget {
  const _SupabaseStatus();

  @override
  Widget build(BuildContext context) {
    final isConfigured = SupabaseConfig.isConfigured;
    final color = isConfigured
        ? const Color(0xFF0F766E)
        : const Color(0xFF9A3412);
    final text = isConfigured
        ? 'Supabase: da cau hinh'
        : 'Supabase: thieu SUPABASE_URL / SUPABASE_ANON_KEY';

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConfigured ? Icons.cloud_done : Icons.cloud_off,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.player, required this.onTap});

  final Player? player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCFC6B4), width: 0.5),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              player?.label ?? '',
              style: TextStyle(
                color: player?.color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Player {
  x('X', Color(0xFFD62828)),
  o('O', Color(0xFF2563EB));

  const Player(this.label, this.color);

  final String label;
  final Color color;
}
