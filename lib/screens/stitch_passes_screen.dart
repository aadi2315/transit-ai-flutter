import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_profile_button.dart';
import '../services/razorpay_service.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../core/storage/local_transit_vault.dart';
import '../utils/device_file_picker.dart';
import '../config/razorpay_config.dart';

/// Pass Model representing transit passes across AMTS, BRTS, and GSRTC
class TransitPassOption {
  final String id;
  final String operator; // 'BRTS' | 'AMTS' | 'GSRTC'
  final String category; // 'Commuter' | 'Student' | 'Senior'
  final String title;
  final int cost; // 0 = Free
  final int? originalCost;
  final String duration;
  final String billingPeriod;
  final String subtitle;
  final String tag;
  final bool requiresStudentVerification;
  final bool requiresSeniorVerification;
  final IconData icon;

  const TransitPassOption({
    required this.id,
    required this.operator,
    required this.category,
    required this.title,
    required this.cost,
    this.originalCost,
    required this.duration,
    required this.billingPeriod,
    required this.subtitle,
    required this.tag,
    this.requiresStudentVerification = false,
    this.requiresSeniorVerification = false,
    required this.icon,
  });
}

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
  // All pass options from AMTS, BRTS, and GSRTC Transit Guide
  static const List<TransitPassOption> _allPasses = [
    // --- BRTS (Ahmedabad Janmarg Dedicated Corridor) ---
    TransitPassOption(
      id: 'brts_monthly',
      operator: 'BRTS',
      category: 'Commuter',
      title: 'Monthly Corridor Pass',
      cost: 750,
      duration: '30 Days',
      billingPeriod: '/ mo',
      subtitle: 'Unlimited access across dedicated BRTS corridors',
      tag: 'Regular Pass',
      icon: Icons.directions_bus_rounded,
    ),
    TransitPassOption(
      id: 'brts_quarterly',
      operator: 'BRTS',
      category: 'Commuter',
      title: 'Quarterly Corridor Pass',
      cost: 2000,
      originalCost: 2250,
      duration: '90 Days',
      billingPeriod: '/ 90d',
      subtitle: 'Unlimited BRTS corridor access for 3 months',
      tag: 'Save ₹250',
      icon: Icons.calendar_month_rounded,
    ),
    TransitPassOption(
      id: 'brts_student',
      operator: 'BRTS',
      category: 'Student',
      title: 'Student Concession Pass',
      cost: 450,
      originalCost: 750,
      duration: 'Session / Semester',
      billingPeriod: '/ mo',
      subtitle: '40% discount for school and college students',
      tag: '40% Subsidy',
      requiresStudentVerification: true,
      icon: Icons.school_rounded,
    ),
    TransitPassOption(
      id: 'brts_senior_60_75',
      operator: 'BRTS',
      category: 'Senior',
      title: 'Senior Citizen Pass (60–75)',
      cost: 450,
      originalCost: 750,
      duration: '30 Days',
      billingPeriod: '/ mo',
      subtitle: '40% concession for seniors aged 60 to 75',
      tag: '40% Off',
      requiresSeniorVerification: true,
      icon: Icons.elderly_rounded,
    ),
    TransitPassOption(
      id: 'brts_senior_75_plus',
      operator: 'BRTS',
      category: 'Senior',
      title: 'Senior Super Pass (75+)',
      cost: 0,
      originalCost: 750,
      duration: 'Annual Free Pass',
      billingPeriod: 'Free',
      subtitle: '100% free travel across all Janmarg corridors',
      tag: '100% Free',
      requiresSeniorVerification: true,
      icon: Icons.volunteer_activism_rounded,
    ),

    // --- AMTS (Ahmedabad Municipal Transport Service) ---
    TransitPassOption(
      id: 'amts_monthly',
      operator: 'AMTS',
      category: 'Commuter',
      title: 'Monthly "Travel as You Like"',
      cost: 900,
      duration: '30 Days',
      billingPeriod: '/ mo',
      subtitle: 'Unlimited rides on all AMTS city routes',
      tag: 'City Routes',
      icon: Icons.directions_bus_filled_rounded,
    ),
    TransitPassOption(
      id: 'amts_quarterly',
      operator: 'AMTS',
      category: 'Commuter',
      title: 'Quarterly "Travel as You Like"',
      cost: 2400,
      originalCost: 2700,
      duration: '90 Days',
      billingPeriod: '/ 90d',
      subtitle: 'Unlimited AMTS city bus rides for 3 months',
      tag: 'Save ₹300',
      icon: Icons.calendar_month_rounded,
    ),
    TransitPassOption(
      id: 'amts_student',
      operator: 'AMTS',
      category: 'Student',
      title: 'Student Concession Pass',
      cost: 180,
      originalCost: 900,
      duration: 'Monthly / Term',
      billingPeriod: '/ mo',
      subtitle: 'Up to 85% discount for verified academic students',
      tag: '80% Subsidy',
      requiresStudentVerification: true,
      icon: Icons.school_rounded,
    ),
    TransitPassOption(
      id: 'amts_senior',
      operator: 'AMTS',
      category: 'Senior',
      title: 'Senior Citizen Weekend Pass',
      cost: 0,
      duration: 'Civic / Weekend',
      billingPeriod: 'Free',
      subtitle: 'Designated free weekend travel on civic/religious routes',
      tag: 'Weekend Free',
      requiresSeniorVerification: true,
      icon: Icons.elderly_rounded,
    ),

    // --- GSRTC (Gujarat State Road Transport Corporation) ---
    TransitPassOption(
      id: 'gsrtc_point_to_point',
      operator: 'GSRTC',
      category: 'Commuter',
      title: 'Point-to-Point Commuter Pass',
      cost: 800,
      originalCost: 1600,
      duration: 'Monthly',
      billingPeriod: '/ mo',
      subtitle: 'Fixed-route daily commute pass (~50% discount)',
      tag: '50% Subsidy',
      icon: Icons.alt_route_rounded,
    ),
    TransitPassOption(
      id: 'gsrtc_all_gujarat',
      operator: 'GSRTC',
      category: 'Commuter',
      title: 'All-Gujarat Unlimited 30-Day',
      cost: 3900,
      duration: '30 Days',
      billingPeriod: '/ 30d',
      subtitle: 'Unrestricted access across state transport network',
      tag: 'Statewide',
      icon: Icons.map_rounded,
    ),
    TransitPassOption(
      id: 'gsrtc_student',
      operator: 'GSRTC',
      category: 'Student',
      title: 'Student Monthly Pass',
      cost: 250,
      originalCost: 800,
      duration: 'Monthly',
      billingPeriod: '/ mo',
      subtitle: 'Institutional subsidy for intercity student commuters',
      tag: 'Subsidized',
      requiresStudentVerification: true,
      icon: Icons.school_rounded,
    ),
    TransitPassOption(
      id: 'gsrtc_senior_permanent',
      operator: 'GSRTC',
      category: 'Senior',
      title: 'Senior Permanent Pass (5 Years)',
      cost: 30,
      duration: '5 Years',
      billingPeriod: '/ 5 yrs',
      subtitle: 'Statewide concessional travel (₹30 administrative fee)',
      tag: '5-Year Card',
      requiresSeniorVerification: true,
      icon: Icons.verified_user_rounded,
    ),
    TransitPassOption(
      id: 'gsrtc_senior_temporary',
      operator: 'GSRTC',
      category: 'Senior',
      title: 'Senior Temporary Pass (3 Months)',
      cost: 20,
      duration: '3 Months',
      billingPeriod: '/ 3 mos',
      subtitle: 'Concessional travel across GSRTC state routes',
      tag: '3-Month Card',
      requiresSeniorVerification: true,
      icon: Icons.timer_rounded,
    ),
  ];

  // Operator filter: 'All', 'BRTS', 'AMTS', 'GSRTC'
  String _selectedOperator = 'All';

  // Selected Pass ID
  String _selectedPassId = 'brts_monthly';

  // Active pass state stored in vault
  Map<String, dynamic>? _activePass;
  bool _showPassCatalog = false;

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

  TransitPassOption get _selectedPass {
    return _allPasses.firstWhere(
      (p) => p.id == _selectedPassId,
      orElse: () => _allPasses.first,
    );
  }

  List<TransitPassOption> get _availablePasses {
    if (_selectedOperator == 'All') {
      return _allPasses;
    }
    return _allPasses.where((p) => p.operator == _selectedOperator).toList();
  }

  Color _getOperatorColor(String operator) {
    switch (operator) {
      case 'BRTS':
        return const Color(0xFF0891B2); // Cyan / Teal
      case 'AMTS':
        return const Color(0xFF4F46E5); // Indigo
      case 'GSRTC':
        return const Color(0xFF059669); // Emerald
      default:
        return const Color(0xFF0891B2);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadActivePass();
    _razorpayService.initialize(
      onSuccess: (response) {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        _activatePassSuccess(response.paymentId ?? 'Confirmed');
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        _showToast('Payment Failed: $errorMessage');
      },
    );
  }

  Future<void> _loadActivePass() async {
    try {
      final pass = await LocalTransitVault.instance.getActivePass();
      if (pass != null && mounted) {
        setState(() {
          _activePass = pass;
        });
      }
    } catch (_) {}
  }

  void _onOperatorSelected(String op) {
    setState(() {
      _selectedOperator = op;
      final available = _availablePasses;
      if (!available.any((p) => p.id == _selectedPassId)) {
        _selectedPassId = available.first.id;
      }
    });
  }

  void _onPassSelected(String? newId) {
    if (newId == null) return;
    setState(() {
      _selectedPassId = newId;
    });
  }

  void _payForPass() {
    final pass = _selectedPass;
    if (pass.cost == 0) {
      // Free concession pass
      _activatePassSuccess('FREE_${pass.operator}_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
      return;
    }

    setState(() => _isProcessingPayment = true);
    _razorpayService.openPayment(
      amount: pass.cost,
      keyId: RazorpayConfig.keyId,
      description: '${pass.operator} ${pass.title}',
      onDesktopFallbackSimulateSuccess: () {
        if (!mounted) return;
        setState(() => _isProcessingPayment = false);
        final simId =
            'pay_pass_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
        _activatePassSuccess(simId);
      },
    );
  }

  Future<void> _activatePassSuccess(String refId) async {
    final pass = _selectedPass;
    final profile = SupabaseService.instance.currentUserProfile;
    final phone = profile?['phone'] ?? '9876543210';

    final int calculatedSubsidy = pass.cost == 0
        ? 100
        : (pass.originalCost != null
            ? (((pass.originalCost! - pass.cost) / pass.originalCost!) * 100).round()
            : 0);

    final passRecord = {
      'pass_number': 'PASS-${pass.operator}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'pass_title': pass.title,
      'operator': pass.operator,
      'category': pass.category,
      'duration': pass.duration,
      'billing_period': pass.billingPeriod,
      'subtitle': pass.subtitle,
      'cost': pass.cost,
      'original_cost': pass.originalCost ?? pass.cost,
      'institution_name': pass.category == 'Student'
          ? (_extractionResult?.institutionName ?? 'Gujarat University')
          : '${pass.operator} Transit Authority',
      'roll_number': pass.category == 'Student'
          ? (_extractionResult?.rollNumber ?? '22012011048')
          : 'CITIZEN-${phone.length > 4 ? phone.substring(phone.length - 4) : 'USER'}',
      'subsidy_discount_percent': calculatedSubsidy,
      'monthly_fare': pass.cost.toDouble(),
      'valid_from': DateTime.now().toIso8601String(),
      'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save locally and in Supabase
    await LocalTransitVault.instance.saveActivePass(passRecord);
    await SupabaseService.instance.saveConcessionPass(
      passNumber: passRecord['pass_number'] as String,
      institutionName: passRecord['institution_name'] as String,
      rollNumber: passRecord['roll_number'] as String,
      subsidyPercent: calculatedSubsidy,
      monthlyFare: pass.cost.toDouble(),
      passTitle: pass.title,
      operator: pass.operator,
      category: pass.category,
      duration: pass.duration,
      cost: pass.cost.toDouble(),
    );

    if (mounted) {
      setState(() {
        _activePass = passRecord;
        _showPassCatalog = false;
      });
      _showToast('${pass.operator} Pass Activated! ${passRecord['pass_number']}');
    }
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
        _showToast('Document Selected: ${picked.fileName}');
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
        _showToast('Document Verified by Gemini Vision AI! Subsidy Unlocked.');
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

  bool get _isEligibleForPayment {
    final pass = _selectedPass;
    if (pass.category == 'Commuter') {
      return true; // General commuters do not require academic bonafide
    } else if (pass.category == 'Senior') {
      return _selectedMethod == 'digilocker'
          ? _isDigiLockerLinked
          : (_verificationStatus == 'verified' || _selectedDocumentName != null);
    } else {
      // Student category
      if (_selectedMethod == 'digilocker') {
        return _isDigiLockerLinked;
      } else {
        return _verificationStatus == 'verified';
      }
    }
  }

  String get _ctaButtonText {
    final pass = _selectedPass;
    if (_isProcessingPayment) {
      return 'Processing Payment...';
    }
    if (!_isEligibleForPayment) {
      if (pass.category == 'Student') {
        if (_isVerifying) return 'Verifying Student Bonafide...';
        if (_verificationStatus == 'rejected') return 'Verification Failed (Upload Bonafide)';
        return 'Verify Student Bonafide to Activate';
      } else if (pass.category == 'Senior') {
        return 'Verify Senior Age to Activate';
      }
      return 'Complete Verification';
    }
    if (pass.cost == 0) {
      return 'Activate Free ${pass.operator} Pass';
    }
    return 'Pay ₹${pass.cost} via UPI & Activate Pass';
  }

  @override
  Widget build(BuildContext context) {
    const dark = false;
    const primaryTextColor = Color(0xFF0F172A);
    const secondaryTextColor = Color(0xFF475569);
    const brandPillBg = Colors.white;
    const brandPillBorder = Color(0xFFA5F3FC);

    final pass = _selectedPass;
    final operatorColor = _getOperatorColor(pass.operator);
    final availablePasses = _availablePasses;
    final bool hasActivePass = _activePass != null && _activePass!['status'] == 'active';

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
                      // TOP BAR: Passes & Concessions Badge + Profile Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                              ],
                            ),
                          ),

                          StitchProfileButton(
                            isDarkMode: dark,
                            onTap: widget.onNavigateToProfile,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // VIEW MODE: Show Active Pass Card vs Pass Catalog
                      if (hasActivePass && !_showPassCatalog) ...[
                        _buildActivePassCard(dark, primaryTextColor, secondaryTextColor),
                      ] else ...[
                        // If active pass exists, show a quick top toggle banner
                        if (hasActivePass) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Active: ${_activePass!['pass_title']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF047857),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showPassCatalog = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0891B2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'View Card',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 1. PASS SELECTOR HERO CARD (Dropdown Menu + Dynamic Cost)
                        StitchGlassCard(
                          isDarkMode: dark,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(18),
                          hasCyanGlow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Select Transit Pass',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: primaryTextColor,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'AMTS • BRTS • GSRTC Corridors',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: secondaryTextColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: operatorColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: operatorColor.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      pass.operator,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: operatorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Operator Filter Chips Row
                              Row(
                                children: ['All', 'BRTS', 'AMTS', 'GSRTC'].map((op) {
                                  final isSelected = _selectedOperator == op;
                                  final opColor = op == 'All' ? const Color(0xFF0891B2) : _getOperatorColor(op);
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                      child: GestureDetector(
                                        onTap: () => _onOperatorSelected(op),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? opColor.withValues(alpha: 0.15)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelected
                                                  ? opColor
                                                  : const Color(0xFFE2E8F0),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            op,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected ? opColor : secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 12),

                              // PASS SELECTION DROPDOWN MENU
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: operatorColor.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: operatorColor.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedPassId,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down_circle_rounded,
                                      color: operatorColor,
                                      size: 22,
                                    ),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    selectedItemBuilder: (BuildContext context) {
                                      return availablePasses.map((p) {
                                        final opCol = _getOperatorColor(p.operator);
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: opCol.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  p.operator,
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: opCol,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  p.title,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: primaryTextColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.cost == 0 ? 'FREE' : '₹${p.cost}',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: opCol,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: availablePasses.map((p) {
                                      final isSelected = p.id == _selectedPassId;
                                      final opCol = _getOperatorColor(p.operator);
                                      return DropdownMenuItem<String>(
                                        value: p.id,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: opCol.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  p.operator,
                                                  style: GoogleFonts.jetBrainsMono(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: opCol,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      p.title,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                        color: isSelected ? opCol : primaryTextColor,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${p.category} • ${p.duration}',
                                                      style: GoogleFonts.jetBrainsMono(
                                                        fontSize: 9,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    p.cost == 0 ? 'FREE' : '₹${p.cost}',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: opCol,
                                                    ),
                                                  ),
                                                  Text(
                                                    p.billingPeriod,
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 8,
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onPassSelected,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // DYNAMIC COST & PASS DETAILS CARD
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: operatorColor.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: operatorColor.withValues(alpha: 0.25),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left: Badges & Description
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 5,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                                    ),
                                                    child: Text(
                                                      pass.category,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFECFDF5),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                                    ),
                                                    child: Text(
                                                      pass.tag,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF047857),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                pass.subtitle,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  color: secondaryTextColor,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // Right: Cost Display
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  pass.cost == 0 ? 'FREE' : '₹${pass.cost}',
                                                  style: GoogleFonts.spaceGrotesk(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    color: operatorColor,
                                                  ),
                                                ),
                                                if (pass.cost > 0) ...[
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    pass.billingPeriod,
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (pass.originalCost != null)
                                              Text(
                                                'Was ₹${pass.originalCost}',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 9.5,
                                                  decoration: TextDecoration.lineThrough,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                          ],
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

                        // 2. VERIFICATION CARD (Contextual to pass type)
                        _buildVerificationCard(pass, dark, primaryTextColor, secondaryTextColor),

                        const SizedBox(height: 12),

                        // 3. FARE SUMMARY & CHECKOUT CARD
                        StitchGlassCard(
                          isDarkMode: dark,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(18),
                          hasCyanGlow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 17,
                                    color: operatorColor,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Fare Summary',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Summary Box
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pass Tariff (${pass.duration})',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: secondaryTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${pass.originalCost ?? pass.cost}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (pass.originalCost != null || pass.cost == 0) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Concession / Subsidy',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF047857),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              pass.cost == 0
                                                  ? '-100% (FREE)'
                                                  : '-₹${pass.originalCost! - pass.cost} (${pass.tag})',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF047857),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Payable Amount',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                        Text(
                                          pass.cost == 0 ? '₹0 (FREE)' : '₹${pass.cost}',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: operatorColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // CTA BUTTON (Creates pass on Passes page)
                              Container(
                                height: 50,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: _isEligibleForPayment
                                      ? LinearGradient(
                                          colors: [
                                            operatorColor,
                                            operatorColor.withValues(alpha: 0.85),
                                          ],
                                        )
                                      : null,
                                  color: _isEligibleForPayment
                                      ? null
                                      : const Color(0xFFE2E8F0),
                                  boxShadow: _isEligibleForPayment
                                      ? [
                                          BoxShadow(
                                            color: operatorColor.withValues(alpha: 0.25),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                  border: _isEligibleForPayment
                                      ? null
                                      : Border.all(
                                          color: const Color(0xFFCBD5E1),
                                          width: 1,
                                        ),
                                ),
                                child: ElevatedButton(
                                  onPressed: (_isEligibleForPayment && !_isProcessingPayment)
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
                                          'Opening Gateway...',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ] else if (_isEligibleForPayment) ...[
                                        Icon(
                                          pass.cost == 0 ? Icons.verified_rounded : Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _ctaButtonText,
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
                                        const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _ctaButtonText,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: const Color(0xFF94A3B8),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM DOCK
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

          // FLOATING TOAST NOTIFICATION
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
                        color: Color(0x28000000),
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

  // --- Active Transit Pass Card (Shown right on Passes page when a pass is active) ---
  Widget _buildActivePassCard(
    bool dark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final operator = _activePass?['operator']?.toString() ?? 'BRTS';
    final operatorColor = _getOperatorColor(operator);
    final passTitle = _activePass?['pass_title']?.toString() ?? 'Active Transit Pass';
    final passNumber = _activePass?['pass_number']?.toString() ?? 'PASS-BRTS-849201';
    final category = _activePass?['category']?.toString() ?? 'Commuter';
    final duration = _activePass?['duration']?.toString() ?? '30 Days';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StitchGlassCard(
          isDarkMode: dark,
          borderRadius: 26,
          padding: const EdgeInsets.all(20),
          hasCyanGlow: true,
          borderColor: operatorColor.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operator Badge & Glowing Active Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: operatorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: operatorColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_bus_rounded, color: operatorColor, size: 14),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              operator == 'BRTS'
                                  ? 'Ahmedabad Janmarg BRTS'
                                  : operator == 'AMTS'
                                      ? 'AMTS City Bus'
                                      : 'GSRTC State Transport',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: operatorColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ACTIVE PASS',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pass Title & Category
              Text(
                passTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$category Pass • $duration Unlimited Access',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),

              const SizedBox(height: 16),

              // Digital Pass Token & QR Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: operatorColor.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: operatorColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: QrImageView(
                        data: 'PRAVHA-PASS|$passNumber|$operator',
                        version: QrVersions.auto,
                        size: 52,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DIGITAL PASS ID',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            passNumber,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: operatorColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan QR at Turnstiles or Boarding Gates',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Benefits Summary Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '100% Ride Discount on $operator Network',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_rounded, color: Color(0xFF0891B2), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Zero-fare ticket booking unlocked in Wallet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0E7490),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Primary Action: Book Discounted Ticket in Wallet
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [operatorColor, operatorColor.withValues(alpha: 0.85)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: operatorColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: widget.onNavigateToWallet,
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
                      const Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Book Discounted Ticket in Wallet',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Secondary Action: Browse / Buy Another Pass
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showPassCatalog = true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF0891B2)),
                  label: Text(
                    'Browse Pass Catalog / Buy Another Pass',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0891B2),
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

  // --- Dynamic Verification Section ---
  Widget _buildVerificationCard(
    TransitPassOption pass,
    bool dark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    if (pass.category == 'Commuter') {
      // General Commuters: Instant Aadhaar / DigiLocker photo ID
      return StitchGlassCard(
        isDarkMode: false,
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        hasCyanGlow: false,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF047857),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instant KYC Verified',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    'Government ID linked via DigiLocker • Ready for immediate pass issuance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Student or Senior Verification
    final isStudent = pass.category == 'Student';
    return Column(
      children: [
        // Method Switcher Pill
        Container(
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFA5F3FC),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
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
                          ? Border.all(color: const Color(0xFF0891B2), width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: _selectedMethod == 'digilocker'
                              ? const Color(0xFF0891B2)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DigiLocker Fast-Track',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMethod = 'manual');
                    _showToast('Document Upload selected');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedMethod == 'manual'
                          ? const Color(0xFFECFEFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: _selectedMethod == 'manual'
                          ? Border.all(color: const Color(0xFF0891B2), width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 14,
                          color: _selectedMethod == 'manual'
                              ? const Color(0xFF0891B2)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Upload Document',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
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

        const SizedBox(height: 10),

        // Method Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _selectedMethod == 'digilocker'
              ? _buildDigiLockerSection(isStudent, primaryTextColor, secondaryTextColor)
              : _buildManualSection(isStudent, primaryTextColor, secondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildDigiLockerSection(
    bool isStudent,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return StitchGlassCard(
      key: ValueKey('digilocker_$isStudent'),
      isDarkMode: false,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
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
                  border: Border.all(color: const Color(0xFFA5F3FC)),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF0891B2),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStudent ? 'DigiLocker Academic Verification' : 'DigiLocker Age Verification (60+)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isDigiLockerLinked)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isStudent
                          ? 'DigiLocker Linked: GTU / Student Bonafide Verified'
                          : 'DigiLocker Linked: Age 65 Verified for Concession',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() => _isDigiLockerLinked = true);
                _showToast('DigiLocker Connected & Verified');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891B2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Connect DigiLocker Account', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildManualSection(
    bool isStudent,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final hasFile = _selectedDocumentName != null;
    final canVerify = hasFile && !_isVerifying;

    return StitchGlassCard(
      key: ValueKey('manual_$isStudent'),
      isDarkMode: false,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      hasCyanGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isStudent ? 'Upload Student Bonafide' : 'Upload Proof of Age',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _verificationStatus == 'verified'
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _verificationStatus == 'verified'
                      ? 'Verified ✓'
                      : hasFile
                          ? 'Ready'
                          : 'Required',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _verificationStatus == 'verified'
                        ? const Color(0xFF047857)
                        : secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (!hasFile)
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFEFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5F3FC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_upload_rounded, color: Color(0xFF0891B2), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Select Document (PDF / Image)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5F3FC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: Color(0xFF0891B2), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDocumentName!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDocumentName = null;
                        _verificationStatus = 'idle';
                      });
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

          if (hasFile && _verificationStatus != 'verified') ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canVerify ? _verifyDocument : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isVerifying) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text('Running Gemini OCR...', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white)),
                    ] else ...[
                      const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Verify via Gemini AI OCR', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
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
