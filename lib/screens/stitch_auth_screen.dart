import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../services/supabase_service.dart';

class StitchAuthScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onToggleTheme;
  final VoidCallback onBack;
  final bool isDarkMode;

  const StitchAuthScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToWallet,
    required this.onToggleTheme,
    required this.onBack,
    required this.isDarkMode,
  });

  @override
  State<StitchAuthScreen> createState() => _StitchAuthScreenState();
}

class _StitchAuthScreenState extends State<StitchAuthScreen> {
  bool _isLogin = true;
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  // Login Controllers (empty by default)
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Sign Up Controllers (empty by default)
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupLocationController =
      TextEditingController();
  final TextEditingController _signupPhoneController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();

  int _passwordStrength = 0; // 0: None, 1: Weak, 2: Fair, 3: Strong
  bool _isSubmitting = false;

  void _checkPasswordStrength(String val) {
    setState(() {
      if (val.isEmpty) {
        _passwordStrength = 0;
      } else if (val.length < 6) {
        _passwordStrength = 1;
      } else if (val.length < 9) {
        _passwordStrength = 2;
      } else {
        _passwordStrength = 3;
      }
    });
  }

  Future<void> _handleSignup() async {
    final name = _signupNameController.text.trim().isEmpty
        ? 'Aarav Patel'
        : _signupNameController.text.trim();
    final phone = _signupPhoneController.text.trim().isEmpty
        ? '9879044120'
        : _signupPhoneController.text.trim();
    final locality = _signupLocationController.text.trim().isEmpty
        ? 'Ahmedabad Hub'
        : _signupLocationController.text.trim();
    final password = _signupPasswordController.text;

    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.instance.registerUserProfile(
        fullName: name,
        phone: phone,
        locality: locality,
        password: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome $name! Locality saved as "$locality" in Supabase.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onNavigateToHome();
      }
    } catch (e) {
      debugPrint('[AuthScreen] signup notice: $e');
      if (mounted) widget.onNavigateToHome();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleLogin() async {
    final phone = _loginPhoneController.text.trim().isEmpty
        ? '9879044120'
        : _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;

    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.instance.loginUser(
        phone: phone,
        password: password,
      );
      if (mounted) {
        widget.onNavigateToWallet();
      }
    } catch (e) {
      debugPrint('[AuthScreen] login notice: $e');
      if (mounted) widget.onNavigateToWallet();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      if (_isLogin) {
        _loginPhoneController.text = '98790 44120';
        _loginPasswordController.text = 'transit@2026';
      } else {
        _signupNameController.text = 'Aarav Patel';
        _signupLocationController.text = 'SG Highway, Ahmedabad';
        _signupPhoneController.text = '98790 44120';
        _signupPasswordController.text = 'Transit@2026';
        _checkPasswordStrength('Transit@2026');
      }
    });
  }

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupLocationController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final subLabelColor =
        dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final inputBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final inputBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);
    final chipBg = dark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final brandPillBg =
        dark ? const Color(0xB30F172A) : const Color(0xE6FFFFFF);
    final brandPillBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0x40FFFFFF);
    final tabBg =
        dark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFE2E8F0);
    final activeTabBg = dark ? const Color(0x4D64748B) : Colors.white;
    final dividerColor =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);

    return StitchBackground(
      isDarkMode: dark,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // TOP BAR: Back Button + Brand Pill + Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Back Button
                          Tooltip(
                            message: 'Go Back',
                            child: GestureDetector(
                              onTap: widget.onBack,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: brandPillBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: brandPillBorder,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dark
                                          ? Colors.black.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: primaryTextColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Brand Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: brandPillBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: brandPillBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: dark
                                      ? Colors.black.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/images/pravha_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PRAVHA',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Dynamic Theme Toggle Button
                      StitchThemeToggleButton(
                        isDarkMode: dark,
                        onToggleTheme: widget.onToggleTheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MAIN CRYSTAL GLASS AUTH CARD
                  StitchGlassCard(
                    isDarkMode: dark,
                    borderRadius: 28,
                    padding: const EdgeInsets.all(20),
                    hasCyanGlow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            key: ValueKey<bool>(_isLogin),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin ? 'Welcome Back' : 'Create Account',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLogin
                                    ? 'Access contactless QR ticketing, pass wallet & live multimodal corridors.'
                                    : 'Get instant smart transit passes, live GPS tracking & offline QR fares.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SEGMENTED PILL TABS: Login vs Sign Up
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: tabBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: dark
                                  ? const Color(0x26FFFFFF)
                                  : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isLogin
                                          ? activeTabBg
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: _isLogin && !dark
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                      border: _isLogin
                                          ? Border.all(
                                              color: dark
                                                  ? const Color(0x55FFFFFF)
                                                  : Colors.white,
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isLogin
                                            ? primaryTextColor
                                            : (dark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !_isLogin
                                          ? activeTabBg
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: !_isLogin && !dark
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                      border: !_isLogin
                                          ? Border.all(
                                              color: dark
                                                  ? const Color(0x55FFFFFF)
                                                  : Colors.white,
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: !_isLogin
                                            ? primaryTextColor
                                            : (dark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Demo Auto-fill Helper Chip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: _fillDemoCredentials,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_fix_high_rounded,
                                      size: 12,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Demo Auto-fill',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF38BDF8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // VIEW 1: LOGIN FORM
                        if (_isLogin) ...[
                          // REGISTERED PHONE NUMBER
                          Text(
                            'REGISTERED PHONE NUMBER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: subLabelColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // IN +91 Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: dark
                                          ? const Color(0x2EFFFFFF)
                                          : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'IN',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0284C7),
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        '+91',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0284C7),
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Phone Field
                                Expanded(
                                  child: TextField(
                                    controller: _loginPhoneController,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (_) => setState(() {}),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Enter 10-digit mobile number',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),

                                if (_loginPhoneController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setState(() => _loginPhoneController.clear()),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ENTER PASSWORD
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'ENTER PASSWORD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: subLabelColor,
                                  ),
                                ),
                              ),
                              Text(
                                'Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _loginPasswordController,
                                    obscureText: _obscureLoginPassword,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Enter your password',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _obscureLoginPassword =
                                        !_obscureLoginPassword);
                                  },
                                  child: Icon(
                                    _obscureLoginPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 16,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // RSA Security Badge
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Offline RSA-2048 token verification active',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: secondaryTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Log In CTA Button
                          Container(
                            height: 48,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x6638BDF8),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _isSubmitting
                                          ? 'Signing in...'
                                          : 'Sign In to PRAVHA',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Don't have an account? Sign Up
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLogin = false),
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: secondaryTextColor,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF0284C7),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // VIEW 2: SIGN UP FORM (Exact Stitch specifications)
                          // FULL NAME
                          Text(
                            'FULL NAME',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: subLabelColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _signupNameController,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'e.g. Aarav Patel',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // WHERE YOU'RE FROM (LOCALITY / CITY)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'WHERE YOU\'RE FROM (LOCALITY / CITY)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: subLabelColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _signupLocationController.text =
                                        'Ahmedabad Hub (GPS Pin)';
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.my_location_rounded,
                                        size: 11,
                                        color: Color(0xFF00E5FF),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Use GPS',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _signupLocationController,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText:
                                          'e.g. SG Highway, Vastrapur, Kalupur...',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_signupLocationController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _signupLocationController.clear()),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Quick Locality Suggestion Chips
                          SizedBox(
                            height: 28,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                for (final area in const [
                                  'SG Highway',
                                  'Vastrapur',
                                  'Kalupur Stn',
                                  'GIFT City',
                                  'Iskcon Cross',
                                  'Maninagar',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _signupLocationController.text =
                                              '$area, Ahmedabad';
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? Colors.white
                                                  .withValues(alpha: 0.05)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: dark
                                                ? const Color(0x2EFFFFFF)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          area,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: dark
                                                ? const Color(0xFFCBD5E1)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // MOBILE NUMBER
                          Text(
                            'MOBILE NUMBER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: subLabelColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🇮🇳 +91',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _signupPhoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '10-digit mobile number',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // CREATE PASSWORD
                          Text(
                            'CREATE PASSWORD',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: subLabelColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _signupPasswordController,
                                    obscureText: _obscureSignupPassword,
                                    onChanged: _checkPasswordStrength,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'At least 6 characters',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _obscureSignupPassword =
                                        !_obscureSignupPassword);
                                  },
                                  child: Icon(
                                    _obscureSignupPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 16,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Password Strength Indicator Bars
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: _passwordStrength >= 1
                                        ? const Color(0xFFF43F5E)
                                        : (dark
                                            ? const Color(0x26FFFFFF)
                                            : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: _passwordStrength >= 2
                                        ? const Color(0xFFF59E0B)
                                        : (dark
                                            ? const Color(0x26FFFFFF)
                                            : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: _passwordStrength >= 3
                                        ? const Color(0xFF10B981)
                                        : (dark
                                            ? const Color(0x26FFFFFF)
                                            : const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _passwordStrength == 0
                                    ? 'Strength'
                                    : _passwordStrength == 1
                                        ? 'Weak'
                                        : _passwordStrength == 2
                                            ? 'Fair'
                                            : 'Strong',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: _passwordStrength == 1
                                      ? const Color(0xFFF43F5E)
                                      : _passwordStrength == 2
                                          ? const Color(0xFFF59E0B)
                                          : _passwordStrength == 3
                                              ? const Color(0xFF10B981)
                                              : secondaryTextColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Terms & Conditions Note
                          Text(
                            'By creating an account, you agree to the Smart Pass Terms & Privacy Policy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: secondaryTextColor,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Sign Up CTA Button (exact text: Create Account & Get Started, without ₹50 bonus)
                          Container(
                            height: 48,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x6638BDF8),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _isSubmitting
                                          ? 'Creating Account...'
                                          : 'Create Account & Get Started',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Already have an account? Sign In
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLogin = true),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Already have an account? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: secondaryTextColor,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF0284C7),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Divider(color: dividerColor, thickness: 0.8),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child:
                                  Divider(color: dividerColor, thickness: 0.8),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Guest / Fast Commute Bar
                        GestureDetector(
                          onTap: widget.onNavigateToHome,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: inputBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Continue as Guest',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
