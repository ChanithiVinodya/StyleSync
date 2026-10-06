import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/auth_state.dart';
import '../../routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() => _localError = null);
    ref.read(authProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, size: 22),
            SizedBox(width: 8),
            Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend API Base URL (cloud host, public tunnel, or local IP):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. http://10.253.20.14:5000/api',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Cloud (Render)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => controller.text = ApiConfig.cloudBackendUrl,
                ),
                ActionChip(
                  label: const Text('Wi-Fi PC (10.253.20.14)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.253.20.14:5000/api',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:5000/api',
                ),
                ActionChip(
                  label: const Text('Localhost (5000)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://localhost:5000/api',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiConfig.updateBaseUrl(newUrl);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server updated to: ${ApiConfig.baseUrl}')),
                  );
                }
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final serverError = authState.errorMessage;
    final displayError = _localError ?? serverError;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF140F0D) : const Color(0xFFEFE7DC);
    final cardBg = isDark ? const Color(0xFF221A17) : const Color(0xFFFAF7F2);
    final primaryColor = isDark ? const Color(0xFFD48270) : const Color(0xFF8C4A3E);
    final textColor = isDark ? const Color(0xFFFAF7F2) : const Color(0xFF241611);
    final subtitleColor = isDark ? const Color(0xFFB5A79E) : const Color(0xFF706053);
    final inputBg = isDark ? const Color(0xFF1A1311) : Colors.white;
    final borderColor = isDark ? const Color(0xFF382B25) : const Color(0xFFE2D6C7);

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Subtle Atmospheric Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF1C1411),
                              const Color(0xFF140E0C),
                              const Color(0xFF0F0B09),
                            ]
                          : [
                              const Color(0xFFEFE7DC),
                              const Color(0xFFE6DAC9),
                              const Color(0xFFD9CAB6),
                            ],
                    ),
                  ),
                ),
              ),

              // Soft Golden Silk Texture Blend
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.15 : 0.30,
                  child: Image.asset(
                    'assets/images/splash_silk_bg.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Gear / Server Settings Button (Top Right)
              Positioned(
                top: 40,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    icon: Icon(Icons.settings_outlined, color: subtitleColor, size: 24),
                    tooltip: 'Configure Server URL',
                    onPressed: _showServerConfigDialog,
                  ),
                ),
              ),

              // Scrollable Responsive Content Container
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.min(constraints.maxWidth, 440.0),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),

                            // Brand Header
                            Center(
                              child: Text(
                                'STYLE SYNC',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 9.0,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                'SIGN IN TO YOUR ATELIER',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 2.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Main Luxury Form Card
                            Container(
                              padding: const EdgeInsets.all(28.0),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: borderColor, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter your credentials to access your interior design projects.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: subtitleColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Error Banner
                                  if (displayError != null && displayError.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB3261E).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFB3261E).withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFB3261E),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              displayError,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFFB3261E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],

                                  // Email Field
                                  Text(
                                    'EMAIL ADDRESS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'client@stylesync.com',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: subtitleColor.withValues(alpha: 0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.mail_outline_rounded,
                                        size: 18,
                                        color: subtitleColor,
                                      ),
                                      filled: true,
                                      fillColor: inputBg,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFB3261E)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Password Field
                                  Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    validator: _validatePassword,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: subtitleColor.withValues(alpha: 0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                        color: subtitleColor,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: subtitleColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: inputBg,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFB3261E)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // "Log in" Primary Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFFD48270)
                                            : const Color(0xFF241611),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: Colors.black.withValues(alpha: 0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'LOG IN',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Navigation Prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(AppRoutes.register);
                                  },
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
