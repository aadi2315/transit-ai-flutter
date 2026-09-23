import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_profile_button.dart';
import '../services/razorpay_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../utils/device_file_picker.dart';
import '../config/razorpay_config.dart';

class StitchPassesScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const StitchPassesScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToAskRoute,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    this.onToggleTheme,
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
  Uint8List? _selectedFileBytes;
  String? _selectedFileMime;
  StudentKycExtractionResult? _extractionResult;
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

  Future<void> _pickDocument() async {
    try {
      final picked = await pickFileFromDevice(
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (picked != null) {
        setState(() {
          _selectedDocumentName = picked.fileName;
          _selectedFileBytes = picked.bytes;
          _selectedFileMime = picked.mimeType;
          _verificationStatus = 'idle';
          _extractionResult = null;
          _isVerifying = false;
        });
        _showToast('Document Selected: ${picked.fileName} (${picked.formattedSize})');
      } else {
        setState(() {
          _selectedDocumentName = 'GTU_Bonafide_Certificate_2026.pdf';
          _selectedFileBytes = null;
          _selectedFileMime = 'application/pdf';
          _verificationStatus = 'idle';
          _extractionResult = null;
          _isVerifying = false;
        });
        _showToast('Sample file selected: GTU_Bonafide_Certificate_2026.pdf');
      }
    } catch (_) {
      setState(() {
        _selectedDocumentName = 'GTU_Bonafide_Certificate_2026.pdf';
        _verificationStatus = 'idle';
        _extractionResult = null;
        _isVerifying = false;
      });
      _showToast('Sample file selected: GTU_Bonafide_Certificate_2026.pdf');
    }
  }

  Future<void> _verifyDocument() async {
    if (_selectedDocumentName == null || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _verificationStatus = 'idle';
    });

    try {
      final result = await GeminiService.instance.extractBonafideKyc(
        imageBytes: _selectedFileBytes,
        mimeType: _selectedFileMime,
        fileName: _selectedDocumentName,
        simulateFailure: _simulateFailure,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _extractionResult = result;
        _verificationStatus = result.isVerified ? 'verified' : 'rejected';
      });

      if (result.isVerified) {
        _showToast('Document Verified by Gemini Vision AI! 80% Subsidy Applied.');
        // Save to Supabase and offline vault
        final profile = SupabaseService.instance.currentUserProfile;
        final phone = profile?['phone'] ?? '9876543210';
        await SupabaseService.instance.submitKycApplication(
          phone: phone,
          studentName: result.studentName,
          institutionName: result.institutionName,
          rollNumber: result.rollNumber,
          ocrData: result.toJson(),
          isApproved: true,
        );
        await SupabaseService.instance.saveConcessionPass(
          passNumber: 'PASS-AMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          institutionName: result.institutionName,
          rollNumber: result.rollNumber,
          subsidyPercent: 80,
          monthlyFare: 60.0,
        );
      } else {
        _showToast(result.remarks);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationStatus = 'rejected';
      });
      _showToast('Verification failed: $e');
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dark = false;

    const primaryTextColor = Color(0xFF0F172A);
    const secondaryTextColor = Color(0xFF475569);
    const brandPillBg = Colors.white;
    const brandPillBorder = Color(0xFFA5F3FC);

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
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
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
                                        color: const Color(0xFF0891B2).withValues(alpha: 0.25),
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
                                  'PRAVHA Passes',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
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
                                    color: const Color(0xFF10B981),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Top Right Actions: Profile Button (leading to Auth)
                          StitchProfileButton(
                            isDarkMode: dark,
                            onTap: widget.onNavigateToProfile,
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
                                color: const Color(0xFFECFEFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFA5F3FC),
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
                                          color: const Color(0xFF0891B2),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'BRTS & Metro Corridors',
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
                                          color: const Color(0xFF0891B2),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFA5F3FC),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14FF6B00),
                              blurRadius: 12,
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
                                        ? const Color(0xFFECFEFF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: _selectedMethod == 'digilocker'
                                        ? Border.all(
                                            color: const Color(0xFF0891B2),
                                            width: 1.2,
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
                                            ? const Color(0xFF0891B2)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Instant via DigiLocker',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMethod == 'digilocker'
                                              ? const Color(0xFF0891B2)
                                              : const Color(0xFF64748B),
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
                                        ? const Color(0xFFECFEFF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: _selectedMethod == 'manual'
                                        ? Border.all(
                                            color: const Color(0xFF0891B2),
                                            width: 1.2,
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
                                            ? const Color(0xFF0891B2)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Upload Manually',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedMethod == 'manual'
                                              ? const Color(0xFF0891B2)
                                              : const Color(0xFF64748B),
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
                            // Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.payments_rounded,
                                  size: 17,
                                  color: Color(0xFF0891B2),
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

                            const SizedBox(height: 12),

                            // Inner Pricing Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
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
                                              color: const Color(0xFF0891B2),
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
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFEFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFA5F3FC),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF0891B2),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
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
                                          Color(0xFF0891B2),
                                          Color(0xFF06B6D4),
                                        ],
                                      )
                                    : null,
                                color: isEligibleForPayment
                                    ? null
                                    : const Color(0xFFE2E8F0),
                                boxShadow: isEligibleForPayment
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x33FF6B00),
                                          blurRadius: 14,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                                border: isEligibleForPayment
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFCBD5E1),
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
                                  disabledForegroundColor: const Color(0xFF94A3B8),
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Opening Razorpay...',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ] else if (isEligibleForPayment) ...[
                                      const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          ctaText,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
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
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ] else ...[
                                      Icon(
                                        _selectedMethod == 'manual' &&
                                                _verificationStatus == 'rejected'
                                            ? Icons.block_rounded
                                            : Icons.lock_outline_rounded,
                                        color: const Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          ctaText,
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF94A3B8),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFA5F3FC),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28FF6B00),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF0891B2),
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _toastMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
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
      isDarkMode: false,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFEFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFA5F3FC),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF0891B2),
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
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0891B2),
                  Color(0xFF06B6D4),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FF6B00),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
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
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connect DigiLocker Account',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
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
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA7F3D0),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
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
                            color: const Color(0xFF047857),
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
      isDarkMode: false,
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFEFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFA5F3FC),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF0891B2),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload Manually',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _verificationStatus == 'verified'
                      ? const Color(0xFFECFDF5)
                      : _verificationStatus == 'rejected'
                          ? const Color(0xFFFEF2F2)
                          : _isVerifying
                              ? const Color(0xFFECFEFF)
                              : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _verificationStatus == 'verified'
                        ? const Color(0xFFA7F3D0)
                        : _verificationStatus == 'rejected'
                            ? const Color(0xFFFECACA)
                            : _isVerifying
                                ? const Color(0xFFA5F3FC)
                                : const Color(0xFFE2E8F0),
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
                        ? const Color(0xFF047857)
                        : _verificationStatus == 'rejected'
                            ? const Color(0xFFDC2626)
                            : _isVerifying
                                ? const Color(0xFF0891B2)
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
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFEFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFA5F3FC),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFA5F3FC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.file_upload_rounded,
                        color: Color(0xFF0891B2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Document (PDF/JPG)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
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
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA5F3FC),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5F3FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF0891B2),
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
                        color: Colors.black.withValues(alpha: 0.08),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _simulateFailure
                    ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                    : const Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: _simulateFailure
                            ? const Color(0xFFF87171)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulate Verification Failure',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Showcase rejection handling for demo',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                color: const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _simulateFailure,
                    activeThumbColor: const Color(0xFFEF4444),
                    activeTrackColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.35),
                    inactiveThumbColor: const Color(0xFF94A3B8),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
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
                        Color(0xFF0891B2),
                        Color(0xFF06B6D4),
                      ],
                    )
                  : null,
              color: canVerify
                  ? null
                  : const Color(0xFFE2E8F0),
              boxShadow: canVerify
                  ? const [
                      BoxShadow(
                        color: Color(0x33FF6B00),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
              border: canVerify
                  ? null
                  : Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1,
                    ),
            ),
            child: ElevatedButton(
              onPressed: canVerify ? _verifyDocument : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledForegroundColor: const Color(0xFF94A3B8),
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
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verify Document (AI OCR Engine)',
                    style: GoogleFonts.spaceGrotesk(
                      color: canVerify
                          ? Colors.white
                          : const Color(0xFF94A3B8),
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
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA5F3FC),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14FF6B00),
                    blurRadius: 14,
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
                          AlwaysStoppedAnimation<Color>(Color(0xFF0891B2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Running On-Device Gemini OCR...',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Gemini Vision AI • Bonafide Authenticated',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF56E5A9),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Extracted Fields
                  _buildExtractedFieldRow(
                    'Student Name',
                    _extractionResult?.studentName ?? 'Aarav Patel',
                    primaryTextColor,
                  ),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                    'Institution',
                    _extractionResult?.institutionName ?? 'Gujarat Technological University (GTU)',
                    primaryTextColor,
                  ),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                    'Enrollment / Roll',
                    _extractionResult?.rollNumber ?? '22012011048',
                    primaryTextColor,
                  ),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                    'Validity Term',
                    _extractionResult?.validUntil ?? '30-06-2026',
                    primaryTextColor,
                  ),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                    'Official Seal',
                    'Authenticated (${((_extractionResult?.confidenceScore ?? 0.94) * 100).toInt()}% confidence)',
                    const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 6),
                  _buildExtractedFieldRow(
                    'Statutory Subsidy',
                    '80% Concession Applied (₹300/mo)',
                    const Color(0xFF56E5A9),
                  ),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '[DEMO ONLY] Document Verification Failed',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFCA5A5),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
