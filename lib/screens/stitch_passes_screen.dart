import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';
import '../services/razorpay_service.dart';
import '../config/razorpay_config.dart';

class StitchPassesScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const StitchPassesScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToAskRoute,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<StitchPassesScreen> createState() => _StitchPassesScreenState();
}

class _StitchPassesScreenState extends State<StitchPassesScreen> {
  // Verification method: 'digilocker' | 'manual'
  String _selectedMethod = 'digilocker';

  // DigiLocker status
  bool _isDigiLockerLinked = true;

  // Manual document upload state variables
  String? _selectedDocumentName;
  bool _isVerifying = false;
  String _verificationStatus = 'idle'; // 'idle', 'verified', 'rejected'
  bool _simulateFailure = false;

  // Toast notification state
  String? _toastMessage;
  Timer? _toastTimer;

  // Razorpay payment state
  final RazorpayService _razorpayService = RazorpayService();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _razorpayService.initialize(
      onSuccess: (response) {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        _showToast('Pass Activated! ID: ${response.paymentId ?? "Confirmed"}');
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            widget.onNavigateToWallet();
          }
        });
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        _showToast('Payment Failed: $errorMessage');
      },
    );
  }

  void _payForPass() {
    setState(() => _isProcessingPayment = true);
    _razorpayService.openPayment(
      amount: 300,
      keyId: RazorpayConfig.keyId,
      description: RazorpayConfig.passBookingDescription,
      onDesktopFallbackSimulateSuccess: () {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        final simId =
            'pay_pass_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        _showToast('Pass Activated! Ref: $simId');
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            widget.onNavigateToWallet();
          }
        });
      },
    );
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _verifyDocument() {
    if (_selectedDocumentName == null || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _verificationStatus = 'idle';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationStatus = _simulateFailure ? 'rejected' : 'verified';
      });
      if (_simulateFailure) {
        _showToast('Verification Failed: Unrecognized seal or expired term');
      } else {
        _showToast('Document Verified Successfully! 80% Concession Applied.');
      }
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final brandPillBg =
        dark ? const Color(0xB30F172A) : const Color(0xE6FFFFFF);
    final brandPillBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0x40FFFFFF);

    final bool isEligibleForPayment;
    final String ctaText;

    if (_selectedMethod == 'digilocker') {
      isEligibleForPayment = _isDigiLockerLinked;
      ctaText = _isDigiLockerLinked
          ? 'Pay ₹300 via UPI & Activate Pass'
          : 'Connect DigiLocker to Activate Pass';
    } else {
      if (_verificationStatus == 'verified') {
        isEligibleForPayment = true;
        ctaText = 'Pay ₹300 via UPI & Activate Subsidized Pass';
      } else if (_isVerifying) {
        isEligibleForPayment = false;
        ctaText = 'Running On-Device Gemini OCR...';
      } else if (_verificationStatus == 'rejected') {
        isEligibleForPayment = false;
        ctaText = 'Verification Failed (Pass Blocked)';
      } else if (_selectedDocumentName == null) {
        isEligibleForPayment = false;
        ctaText = 'Select Document to Activate Subsidized Pass';
      } else {
        isEligibleForPayment = false;
        ctaText = 'Verify Document to Activate Subsidized Pass';
      }
    }

    return StitchBackground(
      isDarkMode: dark,
      child: Stack(
        children: [
          // Scrollable Content
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 410),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP BAR: Passes & Concessions Badge + Theme + Profile Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Passes & Concessions Title Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.badge_rounded,
                                    color: Color(0xFF00354A),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Passes & Concessions',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF56E5A9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF56E5A9),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'KYC LIVE',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF56E5A9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Top Right Actions: Theme Toggle + Profile Button (leading to Auth)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StitchThemeToggleButton(
                                isDarkMode: dark,
                                onToggleTheme: widget.onToggleTheme,
                              ),
                              const SizedBox(width: 8),
                              StitchProfileButton(
                                isDarkMode: dark,
                                onTap: widget.onNavigateToProfile,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 1. HERO CARD (Student & Commuter Passes + Concession Subsidy)
                      StitchGlassCard(
                        isDarkMode: dark,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(18),
                        hasCyanGlow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.40),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 13,
                                        color: Color(0xFF56E5A9),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'AI KYC CONCESSION',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFC4E7FF),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF56E5A9)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF56E5A9)
                                          .withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        size: 13,
                                        color: Color(0xFF56E5A9),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'STUDENT PASS',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF56E5A9),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Heading
                            Text(
                              'Student & Commuter Passes',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify your academic status for an automatic BRTS & Metro student pass discount.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: secondaryTextColor,
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Aligned Monthly Pass Rate Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.12)
                                    : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.40),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'YOUR MONTHLY PASS',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: dark
                                              ? const Color(0xFF8ED5FF)
                                              : const Color(0xFF0284C7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Unlimited BRTS & Metro Corridors',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '₹300',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: dark
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF0284C7),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '/mo',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. VERIFICATION METHOD SWITCHER (Segmented Glass Pill)
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xCC060E20)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.40),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Instant via DigiLocker Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMethod = 'digilocker');
                                  _showToast('DigiLocker Fast-Track selected');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedMethod == 'digilocker'
                                        ? const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: _selectedMethod == 'digilocker'
                                        ? Border.all(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.50),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 15,
                                        color: _selectedMethod == 'digilocker'
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Instant via DigiLocker',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMethod == 'digilocker'
                                              ? (dark
                                                  ? Colors.white
                                                  : const Color(0xFF0284C7))
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Upload Manually Tab
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedMethod = 'manual');
                                  _showToast('Manual Document Upload selected');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedMethod == 'manual'
                                        ? const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.25)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: _selectedMethod == 'manual'
                                        ? Border.all(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.50),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_rounded,
                                        size: 15,
                                        color: _selectedMethod == 'manual'
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Upload Manually',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMethod == 'manual'
                                              ? (dark
                                                  ? Colors.white
                                                  : const Color(0xFF0284C7))
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3. TAB CONTENT: DIGILOCKER or MANUAL
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _selectedMethod == 'digilocker'
                            ? _buildDigiLockerSection(dark, primaryTextColor, secondaryTextColor)
                            : _buildManualSection(dark, primaryTextColor, secondaryTextColor),
                      ),

                      const SizedBox(height: 12),

                      // 4. REAL-TIME STATUS & PRICE CARD (Concession Fare Summary)
                      StitchGlassCard(
                        isDarkMode: dark,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(18),
                        hasCyanGlow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header & Save Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.payments_rounded,
                                      size: 17,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Concession Fare Summary',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF56E5A9)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF56E5A9)
                                          .withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Save ₹1,200/mo',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF56E5A9),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Inner Pricing Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '₹300',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF38BDF8),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '/ month',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Includes Govt Concession Subsidy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF56E5A9),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.20),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF38BDF8),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Subtitle Details with Infinity icon
                            Row(
                              children: [
                                const Icon(
                                  Icons.all_inclusive_rounded,
                                  size: 15,
                                  color: Color(0xFF38BDF8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Unlimited trips on BRTS corridors & Metro Phase 1 • Auto-renews monthly',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Pay ₹300 via UPI & Activate Pass Button
                            Container(
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: isEligibleForPayment
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF56E5A9),
                                          Color(0xFF38BDF8),
                                        ],
                                      )
                                    : null,
                                color: isEligibleForPayment
                                    ? null
                                    : dark
                                        ? const Color(0xFF1E293B)
                                            .withValues(alpha: 0.60)
                                        : const Color(0xFFE2E8F0),
                                boxShadow: isEligibleForPayment
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x5556E5A9),
                                          blurRadius: 18,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                                border: isEligibleForPayment
                                    ? null
                                    : Border.all(
                                        color: dark
                                            ? const Color(0x22FFFFFF)
                                            : const Color(0xFFCBD5E1),
                                        width: 1,
                                      ),
                              ),
                              child: ElevatedButton(
                                onPressed: (isEligibleForPayment &&
                                        !_isProcessingPayment)
                                    ? _payForPass
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledForegroundColor: dark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isProcessingPayment) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF060E20),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Opening Razorpay...',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: const Color(0xFF060E20),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ] else if (isEligibleForPayment) ...[
                                      const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Color(0xFF060E20),
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          ctaText,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF060E20),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xFF060E20),
                                        size: 17,
                                      ),
                                    ] else ...[
                                      Icon(
                                        _selectedMethod == 'manual' &&
                                                _verificationStatus == 'rejected'
                                            ? Icons.block_rounded
                                            : Icons.lock_outline_rounded,
                                        color: dark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          ctaText,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: dark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM DOCK (PASSES tab active - Index 3)
          StitchBottomDock(
            activeIndex: 3,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 0) {
                widget.onNavigateToHome();
              } else if (index == 1) {
                widget.onNavigateToRouteDetails();
              } else if (index == 2) {
                widget.onNavigateToAskRoute();
              } else if (index == 3) {
                // Already on Passes
              } else if (index == 4) {
                widget.onNavigateToWallet();
              }
            },
          ),

          // FLOATING TOAST NOTIFICATION (matching Stitch)
          if (_toastMessage != null)
            Positioned(
              bottom: 84,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF00B1326),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF56E5A9),
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _toastMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DigiLocker Section Widget ---
  Widget _buildDigiLockerSection(
    bool dark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return StitchGlassCard(
      key: const ValueKey('digilocker'),
      isDarkMode: dark,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF38BDF8),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fast-Track with DigiLocker',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'GOV.IN • NeGD Certified Portal',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Text(
                  '10-Sec Flow',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC4E7FF),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Instantly fetch and verify your government-issued Student Identity / Bonafide directly from API Setu with zero paperwork.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Connect DigiLocker CTA Button
          Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  const Color(0xFF0284C7).withValues(alpha: 0.45),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() => _isDigiLockerLinked = true);
                _showToast('DigiLocker API Handshake Completed! 1 Document Verified.');
              },
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connect DigiLocker Account',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFFC4E7FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF38BDF8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Connected Status Banner
          if (_isDigiLockerLinked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF56E5A9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF56E5A9).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF56E5A9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DigiLocker Linked: GEC/GTU Enrollment Verified',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6FFBBE),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Certificate Authenticated via Digital Signature (SHA-256)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Manual Upload Section Widget ---
  Widget _buildManualSection(
    bool dark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final bool hasFile = _selectedDocumentName != null;
    final bool canVerify = hasFile && !_isVerifying;

    return StitchGlassCard(
      key: const ValueKey('manual'),
      isDarkMode: dark,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Color(0xFF38BDF8),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Manually',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'AI OCR ENGINE • INSTANT VERIFICATION',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _verificationStatus == 'verified'
                      ? const Color(0xFF56E5A9).withValues(alpha: 0.20)
                      : _verificationStatus == 'rejected'
                          ? const Color(0xFFEF4444).withValues(alpha: 0.20)
                          : _isVerifying
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.20)
                              : dark
                                  ? const Color(0xFF222A3D)
                                  : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _verificationStatus == 'verified'
                        ? const Color(0xFF56E5A9).withValues(alpha: 0.40)
                        : _verificationStatus == 'rejected'
                            ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                            : _isVerifying
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.40)
                                : dark
                                    ? const Color(0x33FFFFFF)
                                    : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: Text(
                  _verificationStatus == 'verified'
                      ? 'Verified ✓'
                      : _verificationStatus == 'rejected'
                          ? 'Rejected ✕'
                          : _isVerifying
                              ? 'Analyzing...'
                              : hasFile
                                  ? '1 Doc Ready'
                                  : 'Awaiting Doc',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _verificationStatus == 'verified'
                        ? const Color(0xFF56E5A9)
                        : _verificationStatus == 'rejected'
                            ? const Color(0xFFF87171)
                            : _isVerifying
                                ? const Color(0xFF38BDF8)
                                : secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Upload institutional bonafide certificate to qualify for subsidized student transit fare concession.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // a. File Selection: Interactive Card
          if (!hasFile)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDocumentName = 'GTU_Bonafide_Certificate_2026.pdf';
                  _verificationStatus = 'idle';
                  _isVerifying = false;
                });
                _showToast('Sample file selected: GTU_Bonafide_Certificate_2026.pdf');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.08)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.file_upload_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Document (PDF/JPG)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Display selected file name in a pill with file icon and clear (X) button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDocumentName!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '1.2 MB • Ready for AI OCR Analysis',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDocumentName = null;
                        _verificationStatus = 'idle';
                        _isVerifying = false;
                      });
                      _showToast('Document cleared');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // b. Demo Toggle: Subtle switch to simulate verification failure
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _simulateFailure
                    ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                    : dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: _simulateFailure
                          ? const Color(0xFFF87171)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulate Verification Failure',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'Showcase rejection handling for demo',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _simulateFailure,
                    activeThumbColor: const Color(0xFFEF4444),
                    activeTrackColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.35),
                    inactiveThumbColor: const Color(0xFF94A3B8),
                    inactiveTrackColor: dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      setState(() {
                        _simulateFailure = val;
                        if (_verificationStatus != 'idle') {
                          _verificationStatus = 'idle';
                        }
                      });
                      _showToast(_simulateFailure
                          ? 'Demo Mode: Simulating Verification Failure'
                          : 'Demo Mode: Normal Verification Flow');
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // c. Verify Action: "Verify Document (AI OCR Engine)"
          Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: canVerify
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF38BDF8),
                        Color(0xFF0284C7),
                      ],
                    )
                  : null,
              color: canVerify
                  ? null
                  : dark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.60)
                      : const Color(0xFFE2E8F0),
              boxShadow: canVerify
                  ? const [
                      BoxShadow(
                        color: Color(0x4038BDF8),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
              border: canVerify
                  ? Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.60),
                      width: 1,
                    )
                  : Border.all(
                      color: dark
                          ? const Color(0x22FFFFFF)
                          : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
            ),
            child: ElevatedButton(
              onPressed: canVerify ? _verifyDocument : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledForegroundColor: dark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: canVerify
                        ? Colors.white
                        : (dark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verify Document (AI OCR Engine)',
                    style: GoogleFonts.spaceGrotesk(
                      color: canVerify
                          ? Colors.white
                          : (dark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8)),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Progress Panel: On-Device Gemini OCR
          if (_isVerifying) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Running On-Device Gemini OCR...',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Extracting institutional stamp, student ID & bonafide validity',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // d. Verification Result Card: Success
          if (!_isVerifying && _verificationStatus == 'verified') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF56E5A9).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF56E5A9).withValues(alpha: 0.50),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF56E5A9).withValues(alpha: 0.20),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Green glowing glass badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56E5A9).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF56E5A9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF56E5A9),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '[DEMO ONLY] Document Verified Successfully!',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF56E5A9),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Extracted Fields
                  _buildExtractedFieldRow('Student Name',
                      'Demo Student (Aadi Patel)', primaryTextColor),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                      'College',
                      'Government Engineering College / GTU',
                      primaryTextColor),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow('Document Type',
                      'Bonafide Certificate', primaryTextColor),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                      'Verification Rail',
                      'Digitally Signed (SHA-256 Mock)',
                      const Color(0xFF38BDF8)),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                      'Status',
                      'Verified (Eligible for 80% Concession)',
                      const Color(0xFF56E5A9)),
                ],
              ),
            ),
          ],

          // d. Verification Result Card: Failure
          if (!_isVerifying && _verificationStatus == 'rejected') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red/Amber glowing glass badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '[DEMO ONLY] Document Verification Failed',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFCA5A5),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: Color(0xFFF87171),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Unrecognized seal or expired academic term. Please re-upload a clear bonafide certificate.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedFieldRow(
      String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
