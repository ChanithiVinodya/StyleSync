import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/auth/auth_state.dart';
import '../../routes.dart';
import '../../services/auth/auth_models.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.client;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
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
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() => _localError = null);
    ref.read(authProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          role: _selectedRole,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
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
                                'CREATE YOUR ACCOUNT',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 2.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

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
                                    'Join StyleSync',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Select your profile type and fill out your details.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: subtitleColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

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

                                  // Role Selector (Client vs Designer strictly)
                                  Text(
                                    'I AM JOINING AS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRoleSelectionCard(
                                          role: UserRole.client,
                                          title: 'Client',
                                          subtitle: 'Looking for interior design',
                                          icon: Icons.person_outline_rounded,
                                          isSelected: _selectedRole == UserRole.client,
                                          primaryColor: primaryColor,
                                          borderColor: borderColor,
                                          cardBg: inputBg,
                                          textColor: textColor,
                                          subtitleColor: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildRoleSelectionCard(
                                          role: UserRole.designer,
                                          title: 'Designer',
                                          subtitle: 'Providing design services',
                                          icon: Icons.draw_outlined,
                                          isSelected: _selectedRole == UserRole.designer,
                                          primaryColor: primaryColor,
                                          borderColor: borderColor,
                                          cardBg: inputBg,
                                          textColor: textColor,
                                          subtitleColor: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Full Name Field
                                  Text(
                                    'FULL NAME',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    validator: _validateName,
                                    keyboardType: TextInputType.name,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: _inputDecoration(
                                      hintText: 'Elena Vance',
                                      icon: Icons.badge_outlined,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      primaryColor: primaryColor,
                                      subtitleColor: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

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
                                    decoration: _inputDecoration(
                                      hintText: 'elena@stylesync.com',
                                      icon: Icons.mail_outline_rounded,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      primaryColor: primaryColor,
                                      subtitleColor: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field
                                  Text(
                                    'PASSWORD (MIN. 8 CHARS)',
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
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: _inputDecoration(
                                      hintText: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      primaryColor: primaryColor,
                                      subtitleColor: subtitleColor,
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
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password Field
                                  Text(
                                    'CONFIRM PASSWORD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    validator: _validateConfirmPassword,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleRegister(),
                                    style: TextStyle(fontSize: 14, color: textColor),
                                    decoration: _inputDecoration(
                                      hintText: '••••••••',
                                      icon: Icons.lock_reset_rounded,
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      primaryColor: primaryColor,
                                      subtitleColor: subtitleColor,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: subtitleColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // "Create Account" Primary Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _handleRegister,
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
                                              'CREATE ACCOUNT',
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

                            // Login Navigation Prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                                  },
                                  child: Text(
                                    'Log In',
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

  Widget _buildRoleSelectionCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required Color borderColor,
    required Color cardBg,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.10) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? primaryColor : subtitleColor,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? primaryColor : textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color primaryColor,
    required Color subtitleColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: subtitleColor.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(
        icon,
        size: 18,
        color: subtitleColor,
      ),
      suffixIcon: suffixIcon,
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
    );
  }
}
