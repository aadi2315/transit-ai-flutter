import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';
import '../utils/device_file_picker.dart';

class StitchPassesScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const StitchPassesScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
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

  // Manual document upload state & picked files from device
  PickedDeviceInfo? _studentIdFile;
  PickedDeviceInfo? _bonafideFile;
  bool _isPickingId = false;
  bool _isPickingBonafide = false;

  // Toast notification state
  String? _toastMessage;
  Timer? _toastTimer;

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

  Future<void> _pickStudentIdFromDevice() async {
    setState(() => _isPickingId = true);
    try {
      final file = await pickFileFromDevice(
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file != null) {
        setState(() {
          _studentIdFile = file;
        });
        _showToast('Student ID selected: ${file.fileName} (${file.formattedSize})');
      }
    } catch (e) {
      _showToast('File upload error: $e');
    } finally {
      if (mounted) setState(() => _isPickingId = false);
    }
  }

  Future<void> _pickBonafideFromDevice() async {
    setState(() => _isPickingBonafide = true);
    try {
      final file = await pickFileFromDevice(
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file != null) {
        setState(() {
          _bonafideFile = file;
        });
        _showToast('Bonafide selected: ${file.fileName} (${file.formattedSize})');
      }
    } catch (e) {
      _showToast('File upload error: $e');
    } finally {
      if (mounted) setState(() => _isPickingBonafide = false);
    }
  }

  void _clearStudentId() {
    setState(() {
      _studentIdFile = null;
    });
    _showToast('Student ID document removed');
  }

  void _clearBonafide() {
    setState(() {
      _bonafideFile = null;
    });
    _showToast('Bonafide document removed');
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
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
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF56E5A9),
                                    Color(0xFF38BDF8),
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x5556E5A9),
                                    blurRadius: 18,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _showToast('Pass Activated! Opening Wallet QR Ticket...');
                                  Future.delayed(
                                      const Duration(milliseconds: 600), () {
                                    if (mounted) {
                                      widget.onNavigateToWallet();
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF060E20),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pay ₹300 via UPI & Activate Pass',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: const Color(0xFF060E20),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF060E20),
                                      size: 17,
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

          // BOTTOM DOCK (PASSES tab active - Index 2)
          StitchBottomDock(
            activeIndex: 2,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 0) {
                widget.onNavigateToHome();
              } else if (index == 1) {
                widget.onNavigateToRouteDetails();
              } else if (index == 2) {
                // Already on Passes
              } else if (index == 3) {
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
    final uploadedCount =
        (_studentIdFile != null ? 1 : 0) + (_bonafideFile != null ? 1 : 0);

    return StitchGlassCard(
      key: const ValueKey('manual'),
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
                      Icons.description_rounded,
                      color: Color(0xFFFFB95F),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Document Verification',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        'AI OCR + Instant Device Upload',
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
                  color: uploadedCount == 2
                      ? const Color(0xFF56E5A9).withValues(alpha: 0.20)
                      : dark
                          ? const Color(0xFF222A3D)
                          : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: uploadedCount == 2
                      ? Border.all(
                          color: const Color(0xFF56E5A9).withValues(alpha: 0.40),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  uploadedCount == 2
                      ? '2 of 2 Ready ✓'
                      : uploadedCount == 1
                          ? '1 of 2 Uploaded'
                          : '2 Documents',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: uploadedCount == 2
                        ? const Color(0xFF56E5A9)
                        : secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Click below to choose student credentials directly from your device (PDF, JPG, PNG) for verification.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Document 1: Student ID Card (Front & Back)
          GestureDetector(
            onTap: _studentIdFile == null ? _pickStudentIdFromDevice : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _studentIdFile != null
                    ? const Color(0xFF56E5A9).withValues(alpha: 0.08)
                    : dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _studentIdFile != null
                      ? const Color(0xFF56E5A9).withValues(alpha: 0.50)
                      : dark
                          ? const Color(0x38FFFFFF)
                          : const Color(0xFFCBD5E1),
                  width: _studentIdFile != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _studentIdFile != null
                          ? const Color(0xFF56E5A9).withValues(alpha: 0.20)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _studentIdFile != null
                          ? Icons.verified_user_rounded
                          : Icons.contact_page_rounded,
                      color: _studentIdFile != null
                          ? const Color(0xFF56E5A9)
                          : const Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student ID Card (Front & Back)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          _studentIdFile != null
                              ? '${_studentIdFile!.fileName} (${_studentIdFile!.formattedSize})'
                              : 'Tap to select ID from device (PDF, JPG, PNG)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: _studentIdFile != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _studentIdFile != null
                                ? const Color(0xFF56E5A9)
                                : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_studentIdFile != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF56E5A9)
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF56E5A9),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Uploaded ✓',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF56E5A9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _clearStudentId,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickStudentIdFromDevice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8)
                              .withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF38BDF8),
                            width: 1,
                          ),
                        ),
                        child: _isPickingId
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF38BDF8),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.file_upload_outlined,
                                    size: 14,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Upload',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
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
            ),
          ),

          const SizedBox(height: 8),

          // Document 2: College Bonafide / Fee Receipt
          GestureDetector(
            onTap: _bonafideFile == null ? _pickBonafideFromDevice : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bonafideFile != null
                    ? const Color(0xFF56E5A9).withValues(alpha: 0.08)
                    : dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _bonafideFile != null
                      ? const Color(0xFF56E5A9).withValues(alpha: 0.50)
                      : dark
                          ? const Color(0x38FFFFFF)
                          : const Color(0xFFCBD5E1),
                  width: _bonafideFile != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _bonafideFile != null
                          ? const Color(0xFF56E5A9).withValues(alpha: 0.20)
                          : const Color(0xFFFFB95F).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _bonafideFile != null
                          ? Icons.verified_user_rounded
                          : Icons.receipt_long_rounded,
                      color: _bonafideFile != null
                          ? const Color(0xFF56E5A9)
                          : const Color(0xFFFFB95F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College Bonafide / Fee Receipt',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          _bonafideFile != null
                              ? '${_bonafideFile!.fileName} (${_bonafideFile!.formattedSize})'
                              : 'Tap to select Certificate from device',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: _bonafideFile != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _bonafideFile != null
                                ? const Color(0xFF56E5A9)
                                : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_bonafideFile != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF56E5A9)
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF56E5A9),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Uploaded ✓',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF56E5A9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _clearBonafide,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickBonafideFromDevice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB95F)
                              .withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFB95F),
                            width: 1,
                          ),
                        ),
                        child: _isPickingBonafide
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFB95F),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.file_upload_outlined,
                                    size: 14,
                                    color: Color(0xFFFFB95F),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Upload',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFFB95F),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Submit for Verification Button
          if (uploadedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: uploadedCount == 2
                    ? const LinearGradient(
                        colors: [Color(0xFF56E5A9), Color(0xFF38BDF8)],
                      )
                    : null,
                color: uploadedCount == 2 ? null : const Color(0xFF1E293B),
                boxShadow: uploadedCount == 2
                    ? const [
                        BoxShadow(
                          color: Color(0x4056E5A9),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (uploadedCount == 2) {
                    _showToast(
                        'Both documents submitted for instant AI verification!');
                  } else {
                    _showToast(
                        'Please upload the remaining document from your device');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      uploadedCount == 2
                          ? Icons.verified_rounded
                          : Icons.upload_file_rounded,
                      color: uploadedCount == 2
                          ? const Color(0xFF060E20)
                          : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      uploadedCount == 2
                          ? 'Submit for AI Verification'
                          : 'Upload 1 More Document to Verify',
                      style: GoogleFonts.spaceGrotesk(
                        color: uploadedCount == 2
                            ? const Color(0xFF060E20)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
