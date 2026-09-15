import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'stitch_glass_card.dart';
import '../core/crypto/hmac_signer.dart';
import '../core/storage/local_transit_vault.dart';

class StitchScannerSheet extends StatefulWidget {
  final int fareAmount;
  final String routeName;
  final bool isDarkMode;
  final Function(int amount, String description) onPayWithRazorpay;
  final Function(String paymentId, String terminalName) onScanPaymentComplete;

  const StitchScannerSheet({
    super.key,
    required this.fareAmount,
    required this.routeName,
    required this.isDarkMode,
    required this.onPayWithRazorpay,
    required this.onScanPaymentComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required int fareAmount,
    required String routeName,
    required bool isDarkMode,
    required Function(int amount, String description) onPayWithRazorpay,
    required Function(String paymentId, String terminalName) onScanPaymentComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => StitchScannerSheet(
        fareAmount: fareAmount,
        routeName: routeName,
        isDarkMode: isDarkMode,
        onPayWithRazorpay: onPayWithRazorpay,
        onScanPaymentComplete: onScanPaymentComplete,
      ),
    );
  }

  @override
  State<StitchScannerSheet> createState() => _StitchScannerSheetState();
}

class _StitchScannerSheetState extends State<StitchScannerSheet>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Scan Terminal QR, 1: Show Dynamic UPI QR, 2: Conductor Mode
  late AnimationController _laserController;
  Timer? _qrTimer;
  int _qrCountdown = 180; // 3 minutes
  bool _flashOn = false;
  String _detectedTerminal = 'BRTS-SOLA-GATE-02';
  bool _isScanningTerminal = false;

  // Conductor Shift State
  bool _conductorUnlocked = false;
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;
  ConductorValidationResult? _lastScanResult;
  bool _isCheckingTicket = false;

  final List<Map<String, String>> _availableTerminals = [
    {
      'id': 'BRTS-SOLA-GATE-02',
      'label': 'Sola Gate 02 (Turnstile AFC)',
      'route': 'Line 9U Rapid AC',
      'fare': '₹9.00',
    },
    {
      'id': 'METRO-SHIV-CONC-01',
      'label': 'Shivranjani Metro Interchange Concourse',
      'route': 'East-West Phase 1',
      'fare': '₹9.00',
    },
    {
      'id': 'BUS-8D-COND-SCANNER',
      'label': 'Bus 8D Onboard Handheld POS Scanner',
      'route': 'Feeder Bypass 8D',
      'fare': '₹9.00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_qrCountdown > 1) {
          _qrCountdown--;
        } else {
          _qrCountdown = 180;
        }
      });
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _qrTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _triggerScanDetection(Map<String, String> terminal) {
    setState(() {
      _isScanningTerminal = true;
      _detectedTerminal = terminal['id']!;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _isScanningTerminal = false;
      });
    });
  }

  Future<void> _unlockConductorShift() async {
    final valid = await LocalTransitVault.instance.verifyConductorPin(_pinController.text);
    if (valid) {
      setState(() {
        _conductorUnlocked = true;
        _pinError = null;
      });
    } else {
      setState(() {
        _pinError = 'Invalid Shift PIN. (Default PIN: 1234)';
      });
    }
  }

  void _lockConductorShift() {
    setState(() {
      _conductorUnlocked = false;
      _pinController.clear();
      _pinError = null;
      _lastScanResult = null;
    });
  }

  Future<void> _verifyDynamicPayload(String payload) async {
    setState(() => _isCheckingTicket = true);
    await Future.delayed(const Duration(milliseconds: 250));
    final result = HmacTokenSigner.verifyDynamicPayload(payload);
    if (result.isValid && result.ticketId != null) {
      final isNew = await LocalTransitVault.instance.markTicketValidatedInShift(result.ticketId!);
      if (!isNew) {
        setState(() {
          _isCheckingTicket = false;
          _lastScanResult = ConductorValidationResult(
            isValid: false,
            status: ValidationStatus.alreadyUsed,
            ticketId: result.ticketId,
            origin: result.origin,
            destination: result.destination,
            fare: result.fare,
            message: 'Already Scanned on this vehicle (Duplicate Token)',
          );
        });
        return;
      }
    }
    setState(() {
      _isCheckingTicket = false;
      _lastScanResult = result;
    });
  }

  Future<void> _simulateLiveTicketScan() async {
    final ticket = await LocalTransitVault.instance.getActiveTicket();
    final ticketId = ticket?['ticket_id'] ?? 'TKT-SOLA9987';
    final origin = ticket?['origin'] ?? 'Sola Bhagwat';
    final dest = ticket?['destination'] ?? 'Iskcon Cross Rd';
    final fare = (ticket?['fare'] is num) ? (ticket!['fare'] as num).toDouble() : 9.0;

    final livePayload = HmacTokenSigner.generateDynamicTicketPayload(
      ticketId: ticketId,
      origin: origin,
      destination: dest,
      fare: fare,
    );
    await _verifyDynamicPayload(livePayload);
  }

  Future<void> _simulateExpiredTicketScan() async {
    final expiredTime = DateTime.now().subtract(const Duration(seconds: 45));
    final expiredPayload = HmacTokenSigner.generateDynamicTicketPayload(
      ticketId: 'TKT-EXPIRED-PASS',
      origin: 'Sola Bhagwat',
      destination: 'Iskcon Cross Rd',
      fare: 9.0,
      time: expiredTime,
    );
    await _verifyDynamicPayload(expiredPayload);
  }

  Future<void> _simulateTamperedTicketScan() async {
    const tamperedPayload =
        'TKT-AI|V1|TKT-FAKE999|Sola Bhagwat|Iskcon Cross Rd|9.00|123456|BAD_SIGNATURE_99';
    await _verifyDynamicPayload(tamperedPayload);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: dark ? const Color(0x3838BDF8) : const Color(0x33000000),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF38BDF8),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan & Pay Fare',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Razorpay Gateway • Instant Verification',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: dark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tab Switcher: Scan Terminal vs Show Dynamic QR vs Conductor Shift
              Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: dark
                        ? const Color(0x26FFFFFF)
                        : const Color(0x1A000000),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? const Color(0xFF38BDF8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                size: 13,
                                color: _activeTab == 0
                                    ? const Color(0xFF00354A)
                                    : (dark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Terminal QR',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 0
                                        ? const Color(0xFF00354A)
                                        : (dark
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? const Color(0xFF38BDF8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 14,
                                color: _activeTab == 1
                                    ? const Color(0xFF00354A)
                                    : (dark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Fare UPI QR',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 1
                                        ? const Color(0xFF00354A)
                                        : (dark
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 2
                                ? const Color(0xFF56E5A9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security_rounded,
                                size: 13,
                                color: _activeTab == 2
                                    ? const Color(0xFF00354A)
                                    : (dark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Conductor',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 2
                                        ? const Color(0xFF00354A)
                                        : (dark
                                            ? Colors.white70
                                            : Colors.black54),
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
              ),

              const SizedBox(height: 16),

              if (_activeTab == 0)
                _buildScanTerminalView(dark)
              else if (_activeTab == 1)
                _buildDynamicQrView(dark)
              else
                _buildConductorValidatorView(dark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTerminalView(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Viewfinder Scanner Box
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3338BDF8),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grid background lines
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _ScannerGridPainter(),
                  ),

                  // Center targeting reticle
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isScanningTerminal
                            ? const Color(0xFF56E5A9)
                            : const Color(0xFF38BDF8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Line
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Positioned(
                              top: _laserController.value * 150,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _isScanningTerminal
                                          ? const Color(0xFF56E5A9)
                                          : const Color(0xFF38BDF8),
                                      _isScanningTerminal
                                          ? const Color(0xFF4EDE9E)
                                          : const Color(0xFF00F5FF),
                                      _isScanningTerminal
                                          ? const Color(0xFF56E5A9)
                                          : const Color(0xFF38BDF8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isScanningTerminal
                                          ? const Color(0xFF56E5A9)
                                          : const Color(0xFF38BDF8),
                                      blurRadius: 10,
                                      spreadRadius: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Center Icon
                        Center(
                          child: Icon(
                            _isScanningTerminal
                                ? Icons.check_circle_rounded
                                : Icons.center_focus_strong_rounded,
                            size: 32,
                            color: _isScanningTerminal
                                ? const Color(0xFF56E5A9)
                                : const Color(0x8038BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder corners
                  const Positioned(
                    top: 18,
                    left: 18,
                    child: _CornerMarker(angle: 0),
                  ),
                  const Positioned(
                    top: 18,
                    right: 18,
                    child: _CornerMarker(angle: 90),
                  ),
                  const Positioned(
                    bottom: 18,
                    left: 18,
                    child: _CornerMarker(angle: 270),
                  ),
                  const Positioned(
                    bottom: 18,
                    right: 18,
                    child: _CornerMarker(angle: 180),
                  ),

                  // Torch control button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _flashOn = !_flashOn),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _flashOn
                              ? const Color(0xFF38BDF8)
                              : Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _flashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          size: 15,
                          color: _flashOn ? const Color(0xFF00354A) : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Live Detection Status Pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF56E5A9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF56E5A9).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF56E5A9),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'TERMINAL DETECTED: $_detectedTerminal',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF56E5A9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Detected Fare Details Card
        StitchGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JOURNEY FARE INTENT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                  Text(
                    '₹${widget.fareAmount}.00 INR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.routeName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Automatic interchange pass valid for 90 minutes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Quick Simulated Terminal Scanner Chips
        Text(
          'SELECT AFC TURNSTILE / CONDUCTOR TERMINAL TO SCAN:',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _availableTerminals.map((terminal) {
            final isSelected = _detectedTerminal == terminal['id'];
            return GestureDetector(
              onTap: () => _triggerScanDetection(terminal),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                      : (dark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF38BDF8)
                        : (dark ? const Color(0x26FFFFFF) : const Color(0x26000000)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.nfc_rounded,
                      size: 11,
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        terminal['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (dark ? Colors.white : const Color(0xFF0F172A))
                              : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // CTA: Pay via Razorpay
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            widget.onPayWithRazorpay(
              widget.fareAmount,
              'Transit Ticket Booking - Terminal $_detectedTerminal',
            );
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
                  Icons.payment_rounded,
                  size: 18,
                  color: Color(0xFF00354A),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pay ₹${widget.fareAmount}.00 with Razorpay Gateway',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00354A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Quick Simulated Scanner Pass Button (for instant terminal clearance testing)
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              final fakePaymentId =
                  'pay_scan_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
              widget.onScanPaymentComplete(fakePaymentId, _detectedTerminal);
            },
            icon: const Icon(
              Icons.bolt_rounded,
              size: 14,
              color: Color(0xFF56E5A9),
            ),
            label: Text(
              'Simulate Instant Terminal QR Clearance (Test Bypass)',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: const Color(0xFF56E5A9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicQrView(bool dark) {
    final upiPayload =
        'upi://pay?pa=pravha.rzp@icici&pn=PRAVHA&am=${widget.fareAmount}.00&cu=INR&tn=Ticket-$_detectedTerminal';

    final minutes = (_qrCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_qrCountdown % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'HOLD SCREEN AGAINST TERMINAL SCANNER',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF38BDF8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic QR Frame
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: upiPayload,
              version: QrVersions.auto,
              size: 190.0,
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

        const SizedBox(height: 12),

        // Expiry Countdown & Encryption Badge
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: Color(0xFFFFB95F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in $minutes:$seconds',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFB95F),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF56E5A9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Color(0xFF56E5A9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AES-256 Dynamic Intent',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF56E5A9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Open Razorpay Online Checkout Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            widget.onPayWithRazorpay(
              widget.fareAmount,
              'Dynamic UPI Checkout - Terminal $_detectedTerminal',
            );
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF56E5A9), Color(0xFF38BDF8)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4056E5A9),
                  blurRadius: 16,
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
                  color: Color(0xFF00354A),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pay ₹${widget.fareAmount}.00 Online via Razorpay',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00354A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConductorValidatorView(bool dark) {
    if (!_conductorUnlocked) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF38BDF8),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conductor Shift Authentication',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter 4-digit device PIN to unlock offline HMAC dynamic boarding pass scanner.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: 160,
              decoration: BoxDecoration(
                color: dark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_pinError != null) ...[
              const SizedBox(height: 8),
              Text(
                _pinError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _unlockConductorShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF00354A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Unlock Conductor Scanner (Default: 1234)',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final res = _lastScanResult;
    final bool isSuccess = res?.status == ValidationStatus.valid;
    final bool isExpired = res?.status == ValidationStatus.expiredWindow;
    final bool isUsed = res?.status == ValidationStatus.alreadyUsed;

    Color statusColor = const Color(0xFF56E5A9);
    IconData statusIcon = Icons.verified_rounded;
    String statusTitle = 'READY TO SCAN';

    if (res != null) {
      if (isSuccess) {
        statusColor = const Color(0xFF56E5A9);
        statusIcon = Icons.verified_rounded;
        statusTitle = 'VALID BOARDING PASS';
      } else if (isExpired) {
        statusColor = const Color(0xFFFFB95F);
        statusIcon = Icons.timer_off_rounded;
        statusTitle = 'QR TOKEN EXPIRED';
      } else if (isUsed) {
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.block_rounded;
        statusTitle = 'ALREADY USED / DUPLICATE';
      } else {
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.gpp_bad_rounded;
        statusTitle = 'TAMPERED / FRAUD DETECTED';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active Conductor Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF56E5A9).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF56E5A9).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF56E5A9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AMTS / BRTS SHIFT #8D ACTIVE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF56E5A9),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _lockConductorShift,
                child: Text(
                  'End Shift',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Conductor Scan Result HUD Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: res != null
                ? statusColor.withValues(alpha: 0.10)
                : (dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: res != null ? statusColor.withValues(alpha: 0.6) : const Color(0x33FFFFFF),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: _isCheckingTicket
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                        ),
                      )
                    : Icon(
                        statusIcon,
                        size: 32,
                        color: statusColor,
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                statusTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                res?.message ?? 'Ready for passenger scanning. Point at dynamic HMAC token.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: dark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),

              if (res?.isValid == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'ID: ${res!.ticketId}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      Text(
                        '${res.origin} ➔ ${res.destination}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₹${res.fare?.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF56E5A9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Conductor Test Simulator Buttons
        Text(
          'Offline Conductor Verification Controls:',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _simulateLiveTicketScan,
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Test Live Pass'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF56E5A9).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFF56E5A9),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF56E5A9)),
                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _simulateExpiredTicketScan,
                icon: const Icon(Icons.timer_off_outlined, size: 14),
                label: const Text('Test Expired (>15s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB95F).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFFFFB95F),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFFB95F)),
                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _simulateTamperedTicketScan,
                icon: const Icon(Icons.gpp_bad_outlined, size: 14),
                label: const Text('Test Counterfeit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Privacy Compliance Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0x22FFFFFF),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.privacy_tip_rounded,
                size: 14,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Security Compliant: Commuter phone, identity and financial data are strictly shielded from conductor terminals (PRD §3.4).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CornerMarker extends StatelessWidget {
  final double angle;

  const _CornerMarker({required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * 3.1415926535 / 180,
      child: Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF38BDF8), width: 3),
            left: BorderSide(color: Color(0xFF38BDF8), width: 3),
          ),
        ),
      ),
    );
  }
}

class _ScannerGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1A38BDF8)
      ..strokeWidth = 0.8;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
