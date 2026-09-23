import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_profile_button.dart';
import '../services/razorpay_service.dart';
import '../services/supabase_service.dart';
import '../config/razorpay_config.dart';
import '../core/crypto/hmac_signer.dart';
import '../core/storage/local_transit_vault.dart';

class StitchPaymentQrScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToProfile;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;
  final bool initialIsTicketView;

  const StitchPaymentQrScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToAskRoute,
    required this.onNavigateToPasses,
    required this.onNavigateToProfile,
    this.onToggleTheme,
    required this.isDarkMode,
    this.initialIsTicketView = false,
  });

  @override
  State<StitchPaymentQrScreen> createState() => _StitchPaymentQrScreenState();
}

class _StitchPaymentQrScreenState extends State<StitchPaymentQrScreen>
    with SingleTickerProviderStateMixin {
  bool _isTicketView = false;
  bool _hasPaid = false;
  String _selectedUpi = 'Google Pay';
  bool _receiptExpanded = false;

  late AnimationController _laserController;
  late Timer _totpTimer;
  int _totpSeconds = 15;
  String _dynamicPayload = '';

  // Razorpay & Scanner Integration State
  final RazorpayService _razorpayService = RazorpayService();
  String _paymentId = 'pay_test_amd9987';
  bool _isPaymentProcessing = false;
  final String _terminalId = 'BRTS-SOLA-GATE-02';
  String _paymentMethodUsed = 'Razorpay UPI';

  @override
  void initState() {
    super.initState();
    _isTicketView = widget.initialIsTicketView;
    _hasPaid = widget.initialIsTicketView;
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _loadOfflineActiveTicket();
    _updateDynamicPayload();

    _totpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _totpSeconds = HmacTokenSigner.getRemainingWindowSeconds();
        if (_totpSeconds == 15 || _totpSeconds == 1) {
          _updateDynamicPayload();
        }
      });
    });

    _razorpayService.initialize(
      onSuccess: (response) {
        if (!mounted) return;
        setState(() {
          _isPaymentProcessing = false;
          _paymentId = response.paymentId ??
              'pay_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          _hasPaid = true;
          _isTicketView = true;
          _paymentMethodUsed = 'Razorpay Gateway';
        });
        _updateDynamicPayload();
        _syncTicketToSupabase();
        _showPaymentSnackbar('Payment Successful! Ref: $_paymentId',
            isSuccess: true);
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() {
          _isPaymentProcessing = false;
        });
        _showPaymentSnackbar('Payment Error: $errorMessage', isSuccess: false);
      },
      onExternalWallet: (response) {
        if (!mounted) return;
        setState(() {
          _isPaymentProcessing = false;
        });
        _showPaymentSnackbar('Redirecting to ${response.walletName}');
      },
    );
  }

  Future<void> _loadOfflineActiveTicket() async {
    final cached = await LocalTransitVault.instance.getActiveTicket();
    if (cached != null && mounted) {
      setState(() {
        _hasPaid = true;
        _isTicketView = true;
        if (cached['ticket_id'] != null) {
          _paymentId = cached['ticket_id'].toString().replaceAll('TKT-', '').toLowerCase();
        }
      });
      _updateDynamicPayload();
    }
  }

  void _updateDynamicPayload() {
    _dynamicPayload = HmacTokenSigner.generateDynamicTicketPayload(
      ticketId: 'TKT-${_paymentId.toUpperCase()}',
      origin: 'Sola Bhagwat',
      destination: 'Iskcon Cross Rd',
      fare: 9.0,
      lineInfo: 'BRTS 9U + Feeder 8D',
    );
  }

  Future<void> _syncTicketToSupabase() async {
    try {
      await SupabaseService.instance.saveTicket(
        ticketId: 'TKT-${_paymentId.toUpperCase()}',
        origin: 'Sola Bhagwat',
        destination: 'Iskcon Cross Rd',
        fare: 9.0,
        lineInfo: 'BRTS 9U + Feeder 8D',
        qrPayload: _dynamicPayload,
        hmacSignature: _dynamicPayload.split('|').last,
      );
    } catch (e) {
      debugPrint('[StitchPaymentQrScreen] Ticket sync note: $e');
    }
  }


  @override
  void dispose() {
    _laserController.dispose();
    _totpTimer.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  void _startRazorpayPayment(
      {required int amount, required String description}) {
    setState(() => _isPaymentProcessing = true);
    _razorpayService.openPayment(
      amount: amount,
      keyId: RazorpayConfig.keyId,
      description: description,
      onDesktopFallbackSimulateSuccess: () {
        if (!mounted) return;
        setState(() {
          _isPaymentProcessing = false;
          _paymentId =
              'pay_sim_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          _hasPaid = true;
          _isTicketView = true;
          _paymentMethodUsed = 'Razorpay Simulator';
        });
        _syncTicketToSupabase();
        _showPaymentSnackbar('Payment Verified! Ref: $_paymentId',
            isSuccess: true);
      },
    );
  }

  void _showPaymentSnackbar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isSuccess ? const Color(0xFF0F172A) : const Color(0xFF7F1D1D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSuccess ? const Color(0xFF56E5A9) : const Color(0xFFEF4444),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: isSuccess
                  ? const Color(0xFF56E5A9)
                  : const Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dark = false;

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
                constraints: const BoxConstraints(maxWidth: 480),
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF0F172A),
                                size: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFEFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFA5F3FC)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0891B2).withValues(alpha: 0.15),
                                          blurRadius: 4,
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
                                  Flexible(
                                    child: Text(
                                      _isTicketView
                                          ? 'PRAVHA Dynamic Pass'
                                          : 'PRAVHA Fare Checkout',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StitchProfileButton(
                            isDarkMode: dark,
                            onTap: widget.onNavigateToProfile,
                            size: 36,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // TOP MODE SWITCHER TABS: Fare Checkout vs Dynamic QR Ticket
                      Container(
                        height: 42,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFA5F3FC),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0891B2).withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTicketView = false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: !_isTicketView
                                        ? const LinearGradient(
                                            colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.payment_rounded,
                                          size: 14,
                                          color: !_isTicketView
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Fare Checkout',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: !_isTicketView
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isTicketView = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _isTicketView
                                        ? const LinearGradient(
                                            colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 14,
                                          color: _isTicketView
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Dynamic QR Ticket',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _isTicketView
                                                ? Colors.white
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFA5F3FC),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0891B2).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS LOCK: ACTIVE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ETA: 4 MIN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFEFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA5F3FC)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0891B2).withValues(alpha: 0.15),
                                blurRadius: 4,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sola Crossroad → Iskcon Circle',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Interchange at Shivranjani',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0891B2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹9.00',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0891B2),
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Header Block
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'Unified Fare Checkout',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFF0891B2),
                          ),
                        ],
                      ),
                      Text(
                        'Valid for 1 journey within 90 mins',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'SECURE INTENT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          'ROUTE BREAKDOWN • 2 LEGS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '8.4 km • ~24 mins',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
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
                            color: const Color(0xFF0891B2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '9U',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Rapid AC Line • 5 stops (4.8 km, 13 min)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
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
                            color: const Color(0xFF0F172A),
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
                        color: const Color(0xFFECFEFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA5F3FC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.transfer_within_a_station_rounded,
                            size: 13,
                            color: Color(0xFF0891B2),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Interchange at Shivranjani Junction',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            '3 min walk',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0891B2),
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
                            color: const Color(0xFF06B6D4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '8D',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Feeder Bypass • 3 stops (3.6 km, 8 min)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
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
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Color(0xFFE2E8F0), height: 18),

                    // Total
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              'Unified Total Fare',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Multi-Leg QR',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
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
                            color: const Color(0xFF0891B2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // FAST UPI CHECKOUT Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    'FAST UPI CHECKOUT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '0% Convenience Fee',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: const Color(0xFF16A34A),
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
                      const Color(0xFFEA4335)),
                  _buildUpiOption('PhonePe', 'Linked VPA', 'P',
                      const Color(0xFF9333EA)),
                  _buildUpiOption('Paytm', 'Fast UPI', '₹',
                      const Color(0xFF0284C7)),
                  _buildUpiOption('Any UPI ID', 'Enter handle', '@',
                      const Color(0xFF0891B2)),
                ],
              ),

              const SizedBox(height: 14),

              // Gateway Info Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded,
                            size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(
                          'Razorpay Test Mode',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'YOUR_RAZORPAY_KEY_ID',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Pay CTA Button
              GestureDetector(
                onTap: _isPaymentProcessing
                    ? null
                    : () {
                        _startRazorpayPayment(
                          amount: 9,
                          description: 'Transit Fare ₹9.00 via $_selectedUpi',
                        );
                      },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40FF6B00),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isPaymentProcessing) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Opening Razorpay Checkout...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.payment_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Pay ₹9.00 via $_selectedUpi',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // DEDICATED UPI PAYMENT QR SECTION (For scanning & paying ₹9.00)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFA5F3FC),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0891B2).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFEFF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFA5F3FC)),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 16,
                                  color: Color(0xFF0891B2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Pay via UPI QR Code',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFEFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA5F3FC)),
                          ),
                          child: Text(
                            'PAYMENT QR',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan this payment QR with GPay, PhonePe, Paytm, or any UPI app to pay ₹9.00. Your ticket QR unlocks in the Ticket section once payment is confirmed.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA5F3FC)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data:
                              'upi://pay?pa=pravha.rzp@icici&pn=PRAVHA&am=9.00&cu=INR&tn=Ticket-Sola-Iskcon',
                          version: QrVersions.auto,
                          size: 140.0,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'UPI ID: pravha.rzp@icici • Fare: ₹9.00',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _paymentId =
                              'pay_qr_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                          _hasPaid = true;
                          _isTicketView = true;
                          _paymentMethodUsed = 'Dynamic UPI QR';
                        });
                        _syncTicketToSupabase();
                        _showPaymentSnackbar(
                            'UPI QR Payment Verified! Ref: $_paymentId',
                            isSuccess: true);
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF16A34A),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Confirm / Simulate UPI QR Payment Received',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                                overflow: TextOverflow.ellipsis,
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
              ? const Color(0xFFECFEFF)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0891B2)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFEDD5)
                    : const Color(0xFFF1F5F9),
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
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: const Color(0xFF64748B),
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
                  color: Color(0xFF0891B2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketView() {
    if (!_hasPaid) {
      return _buildNoActiveTicketView();
    }
    return _buildActiveTicketQrView();
  }

  Widget _buildNoActiveTicketView() {
    return StitchGlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      hasCyanGlow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Locked Icon Circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA5F3FC),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0891B2).withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 34,
              color: Color(0xFF0891B2),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFA5F3FC),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: Color(0xFF0891B2),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'PAYMENT REQUIRED • NO ACTIVE TICKET',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0891B2),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title & Description
          Text(
            'No Active Ticket Yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your cryptographic dynamic QR boarding ticket will be generated automatically as soon as your fare payment is confirmed. Please complete payment in the Fare Checkout section.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          // Pending Route Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFA5F3FC),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5F3FC)),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
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
                        'Sola Crossroad → Iskcon Circle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Fare: ₹9.00 • 2 Legs (9U ➔ 8D)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹9.00',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Big Proceed to Payment Button
          GestureDetector(
            onTap: () => setState(() => _isTicketView = false),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40FF6B00),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Proceed to Payment (₹9.00)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 12,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Anti-Fraud Protected • Ticket QR generates on payment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTicketQrView() {
    return StitchGlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      hasCyanGlow: false,
      child: Column(
        children: [
          // Header: Ahmedabad BRTS + CONFIRMED
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 18,
                      color: Color(0xFF0891B2),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Ahmedabad BRTS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF86EFAC),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CONFIRMED',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
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
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5F3FC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Sola Bhagwat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF0891B2)),
                    Text(
                      'Iskcon Cross Rd',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA5F3FC)),
                      ),
                      child: Text(
                        'AC Electric • 9U ➔ 8D',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0891B2),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Single Stage',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      '₹9.00 Paid',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Adult / General Passenger',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Platform 02 • Gate D',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    border: Border.all(color: const Color(0xFFA5F3FC)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0891B2).withValues(alpha: 0.1),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      QrImageView(
                        data: _dynamicPayload.isNotEmpty
                            ? _dynamicPayload
                            : HmacTokenSigner.generateDynamicTicketPayload(
                                ticketId: 'TKT-${_paymentId.toUpperCase()}',
                                origin: 'Sola Bhagwat',
                                destination: 'Iskcon Cross Rd',
                                fare: 9.0,
                              ),
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
                                    Color(0xFF0891B2),
                                    Color(0xFFFFA000),
                                    Color(0xFF0891B2),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF0891B2),
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
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      _paymentId,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                  ],
                ),
                Text(
                  'HMAC-SHA256 Signed Dynamic Token • Rotates Every 15s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 10),

                // Anti-Fraud TOTP Rotating Ring + NFC Ready
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFA5F3FC),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0891B2).withValues(alpha: 0.05),
                        blurRadius: 6,
                      ),
                    ],
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
                              color: const Color(0xFF0891B2),
                              backgroundColor: const Color(0xFFECFEFF),
                            ),
                            Text(
                              '$_totpSeconds',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
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
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Rotates dynamically',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFEFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA5F3FC)),
                        ),
                        child: Text(
                          'NFC READY',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0891B2),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                ),
              ],
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
                        Expanded(
                          child: Text(
                            'Digital Receipt & Turnstile Guide',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(
                          _receiptExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: const Color(0xFF64748B),
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
                            color: Color(0xFFE2E8F0), height: 12),
                        _buildReceiptRow('Base Transit Fare', '₹9.00'),
                        _buildReceiptRow('SGST / CGST (0%)', '₹0.00'),
                        _buildReceiptRow('Razorpay Ref ID', _paymentId),
                        _buildReceiptRow('Payment Method', _paymentMethodUsed),
                        _buildReceiptRow('Gateway Account', 'PRAVHA (${RazorpayConfig.keyId.substring(0, 8)}...)'),
                        _buildReceiptRow('AFC Turnstile Gate', _terminalId),
                        const SizedBox(height: 6),
                        Text(
                          'Hold phone 2-4 inches above the AFC turnstile scanner at Platform 02 Gate D.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action: Book Another Journey / Reset
          GestureDetector(
            onTap: () {
              setState(() {
                _hasPaid = false;
                _isTicketView = false;
              });
            },
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA5F3FC),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    size: 15,
                    color: Color(0xFF0891B2),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Book Another Journey / New Ticket',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
                  fontSize: 10, color: const Color(0xFF64748B))),
          Text(val,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
