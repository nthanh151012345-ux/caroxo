import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.userEmail,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu mới phải khác mật khẩu hiện tại.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Re-authenticate để kiểm tra mật khẩu cũ
      await SupabaseConfig.client!.auth.signInWithPassword(
        email: widget.userEmail,
        password: _currentPasswordController.text,
      );

      // 2. Cập nhật mật khẩu mới
      await SupabaseConfig.client!.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (!mounted) return;

      // 3. Hiển thị Dialog báo thành công và Đăng xuất
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Thành công'),
            ],
          ),
          content: const Text(
            'Mật khẩu của bạn đã được cập nhật thành công. Ứng dụng sẽ đăng xuất để bạn đăng nhập lại bằng mật khẩu mới.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng Dialog
                Navigator.of(context).pop(); // Quay lại GameSetupScreen
                widget.onSignOut(); // Đăng xuất
              },
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login credentials') || msg.contains('invalid_credentials')) {
        msg = 'Mật khẩu hiện tại không chính xác.';
      } else if (msg.contains('Password should be')) {
        msg = 'Mật khẩu mới không đáp ứng yêu cầu độ mạnh mật khẩu của hệ thống.';
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('HỒ SƠ CÁ NHÂN'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card chứa Form đổi mật khẩu
                    Container(
                      padding: const EdgeInsets.all(24),
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
                              Icon(Icons.lock_reset_rounded, size: 24, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'THAY ĐỔI MẬT KHẨU',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Ô nhập Mật khẩu Hiện tại
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              labelText: 'Mật khẩu hiện tại',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscureCurrent ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrent = !_obscureCurrent;
                                  });
                                },
                                icon: Icon(
                                  _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu hiện tại.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ô nhập Mật khẩu Mới
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              labelText: 'Mật khẩu mới',
                              prefixIcon: const Icon(Icons.lock_open_outlined),
                              suffixIcon: IconButton(
                                tooltip: _obscureNew ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscureNew = !_obscureNew;
                                  });
                                },
                                icon: Icon(
                                  _obscureNew ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới.';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu mới phải có tối thiểu 6 ký tự.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ô xác nhận Mật khẩu Mới
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              labelText: 'Xác nhận mật khẩu mới',
                              prefixIcon: const Icon(Icons.lock_person_outlined),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirm ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu mới.';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Mật khẩu xác nhận không khớp.';
                              }
                              return null;
                            },
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút đổi mật khẩu Gradient
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            else ...[
                              const Icon(Icons.published_with_changes_rounded, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'XÁC NHẬN ĐỔI MẬT KHẨU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
