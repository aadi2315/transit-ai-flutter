import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';

class StitchPaymentQrScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final bool initialIsTicketView;

  const StitchPaymentQrScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToAskRoute,
    required this.onNavigateToPasses,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.initialIsTicketView = false,
  });

  @override
  State<StitchPaymentQrScreen> createState() => _StitchPaymentQrScreenState();
}

class _StitchPaymentQrScreenState extends State<StitchPaymentQrScreen>
    with SingleTickerProviderStateMixin {
  bool _isTicketView = false;
  String _selectedUpi = 'Google Pay';
  bool _receiptExpanded = false;

  late AnimationController _laserController;
  late Timer _totpTimer;
  int _totpSeconds = 15;

  @override
  void initState() {
    super.initState();
    _isTicketView = widget.initialIsTicketView;
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_totpSeconds > 1) {
          _totpSeconds--;
        } else {
          _totpSeconds = 15;
        }
      });
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _totpTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

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
                constraints: const BoxConstraints(maxWidth: 390),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 8, bottom: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Back & Theme
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: widget.onNavigateToRouteDetails,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xB30F172A) : const Color(0xE6FFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: dark ? const Color(0x38FFFFFF) : const Color(0x40FFFFFF),
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
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                                size: 16,
                              ),
                            ),
                          ),
                          Text(
                            _isTicketView
                                ? 'Dynamic QR Pass'
                                : 'Unified Fare Checkout',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StitchProfileButton(
                                isDarkMode: dark,
                                onTap: widget.onNavigateToProfile,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              StitchThemeToggleButton(
                                isDarkMode: dark,
                                onToggleTheme: widget.onToggleTheme,
                                size: 36,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // TOP MODE SWITCHER TABS: Fare Checkout vs Dynamic QR Ticket
                      Container(
                        height: 42,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0x26FFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTicketView = false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isTicketView
                                        ? const Color(0xFF38BDF8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.payment_rounded,
                                        size: 14,
                                        color: !_isTicketView
                                            ? const Color(0xFF00354A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Fare Checkout',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: !_isTicketView
                                              ? const Color(0xFF00354A)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTicketView = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isTicketView
                                        ? const Color(0xFF38BDF8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 14,
                                        color: _isTicketView
                                            ? const Color(0xFF00354A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dynamic QR Ticket',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _isTicketView
                                              ? const Color(0xFF00354A)
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

                      // VIEW CONTENT: Checkout vs Ticket
                      if (!_isTicketView)
                        _buildCheckoutView()
                      else
                        _buildTicketView(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM DOCK (WALLET tab active - Index 4)
          StitchBottomDock(
            activeIndex: 4,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 0) {
                widget.onNavigateToHome();
              } else if (index == 1) {
                widget.onNavigateToRouteDetails();
              } else if (index == 2) {
                widget.onNavigateToAskRoute();
              } else if (index == 3) {
                widget.onNavigateToPasses();
              } else if (index == 4) {
                // Already on Wallet
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Peeking Map Header Card
        Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x26FFFFFF),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56E5A9).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF56E5A9),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS LOCK: ACTIVE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF56E5A9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ETA: 4 MIN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alt_route_rounded,
                          color: Color(0xFF00354A),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sola Crossroad → Iskcon Circle',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Interchange at Shivranjani',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹9.00',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Pull-Up Liquid Glass Drawer Base
        StitchGlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Header Block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Unified Fare Checkout',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFF38BDF8),
                          ),
                        ],
                      ),
                      Text(
                        'Valid for 1 journey within 90 mins',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFF56E5A9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SECURE INTENT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Itemized Breakdown Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x26FFFFFF),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ROUTE BREAKDOWN • 2 LEGS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        Text(
                          '8.4 km • ~24 mins',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Leg 1
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '9U',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF00354A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sola Crossroad → Shivranjani',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Rapid AC Line • 5 stops (4.8 km, 13 min)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹5.00',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Concourse transfer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.transfer_within_a_station_rounded,
                            size: 13,
                            color: Color(0xFF56E5A9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Interchange at Shivranjani Junction',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '3 min walk',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF56E5A9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Leg 2
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB95F),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '8D',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shivranjani → Iskcon Circle',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Feeder Bypass • 3 stops (3.6 km, 8 min)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹4.00',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Color(0x26FFFFFF), height: 18),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Unified Total Fare',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF56E5A9)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Multi-Leg QR',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF56E5A9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'INR ₹9.00',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // FAST UPI CHECKOUT 2x2 Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FAST UPI CHECKOUT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  Text(
                    '0% Convenience Fee',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: const Color(0xFF56E5A9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildUpiOption('Google Pay', 'Instant Intent', 'G',
                      const Color(0xFF38BDF8)),
                  _buildUpiOption('PhonePe', 'Linked VPA', 'P',
                      const Color(0xFF9333EA)),
                  _buildUpiOption('Paytm', 'Fast UPI', '₹',
                      const Color(0xFF0284C7)),
                  _buildUpiOption('Any UPI ID', 'Enter handle', '@',
                      const Color(0xFF94A3B8)),
                ],
              ),

              const SizedBox(height: 14),

              // Pay CTA Button
              GestureDetector(
                onTap: () {
                  setState(() => _isTicketView = true);
                },
                child: Container(
                  height: 48,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: Color(0xFF00354A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pay ₹9.00 via $_selectedUpi',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00354A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isTicketView = true),
                  child: Text(
                    'Or scan dynamic UPI QR code on terminal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpiOption(
      String name, String subtitle, String iconText, Color accentColor) {
    final isSelected = _selectedUpi == name;

    return GestureDetector(
      onTap: () => setState(() => _selectedUpi = name),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : const Color(0x26FFFFFF),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                iconText,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF38BDF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Color(0xFF00354A),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketView() {
    return StitchGlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: true,
      child: Column(
        children: [
          // Header: Ahmedabad BRTS + CONFIRMED
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    size: 18,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ahmedabad BRTS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF56E5A9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF56E5A9).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFF56E5A9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CONFIRMED',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF56E5A9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Journey Segment Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sola Bhagwat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      'Iskcon Cross Rd',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AC Electric • 9U ➔ 8D',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Single Stage',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹9.00 Paid',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFB95F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adult / General Passenger',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'Platform 02 • Gate D',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // High-Contrast Dynamic QR Box with Animated Laser Beam
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      QrImageView(
                        data:
                            'TRANSIT_AI|V3|TKN-AMD-9987-OFFLINE|SOLA_TO_ISKCON|FARE_9.00|GATE_D',
                        version: QrVersions.auto,
                        size: 160.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      // Animated Laser Beam
                      AnimatedBuilder(
                        animation: _laserController,
                        builder: (context, child) {
                          return Positioned(
                            top: _laserController.value * 145,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2.5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF38BDF8),
                                    Color(0xFF00F5FF),
                                    Color(0xFF38BDF8),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 14, color: Color(0xFF56E5A9)),
                    const SizedBox(width: 4),
                    Text(
                      'TKN-AMD-9987-OFFLINE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                Text(
                  'AES-256 Authenticated GTFS Payload',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    color: const Color(0xFF94A3B8),
                  ),
                ),

                const SizedBox(height: 10),

                // Anti-Fraud TOTP Rotating Ring + NFC Ready
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x26FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Countdown Ring
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _totpSeconds / 15.0,
                              strokeWidth: 2.5,
                              color: const Color(0xFF38BDF8),
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
                            Text(
                              '$_totpSeconds',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anti-Fraud TOTP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Rotates dynamically',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                color: const Color(0xFF56E5A9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'NFC READY',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Digital Receipt Accordion
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0x26FFFFFF),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _receiptExpanded = !_receiptExpanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Digital Receipt & Turnstile Guide',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          _receiptExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_receiptExpanded)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: Column(
                      children: [
                        const Divider(
                            color: Color(0x26FFFFFF), height: 12),
                        _buildReceiptRow('Base Transit Fare', '₹9.00'),
                        _buildReceiptRow('SGST / CGST (0%)', '₹0.00'),
                        _buildReceiptRow('Ref ID', 'TXN-AHM-889104'),
                        const SizedBox(height: 6),
                        Text(
                          'Hold phone 2-4 inches above the AFC turnstile scanner at Platform 02 Gate D.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: const Color(0xFFCBD5E1),
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

  Widget _buildReceiptRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: const Color(0xFF94A3B8))),
          Text(val,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
