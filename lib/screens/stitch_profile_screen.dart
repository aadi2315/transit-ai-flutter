import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_background.dart';
import '../services/supabase_service.dart';
import '../core/storage/local_transit_vault.dart';

class StitchProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToLogin;
  final VoidCallback onLoggedOut;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const StitchProfileScreen({
    super.key,
    required this.onBack,
    required this.onNavigateToHome,
    required this.onNavigateToWallet,
    required this.onNavigateToPasses,
    required this.onNavigateToLogin,
    required this.onLoggedOut,
    this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<StitchProfileScreen> createState() => _StitchProfileScreenState();
}

class _StitchProfileScreenState extends State<StitchProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeTicket;
  Map<String, dynamic>? _activePass;
  int _pastJourneysCount = 0;
  bool _isLoading = true;

  // Selected preferred modes
  final Set<String> _preferredModes = {'Metro', 'BRTS'};

  @override
  void initState() {
    super.initState();
    _loadProfileAndVaultData();
  }

  Future<void> _loadProfileAndVaultData() async {
    setState(() => _isLoading = true);
    try {
      final profile = SupabaseService.instance.currentUserProfile;
      final ticket = await LocalTransitVault.instance.getActiveTicket();
      final pass = await LocalTransitVault.instance.getActivePass();
      final journeys = await LocalTransitVault.instance.getPastJourneys();

      if (mounted) {
        setState(() {
          _profile = profile;
          _activeTicket = ticket;
          _activePass = pass;
          _pastJourneysCount = journeys.length;

          // Parse preferred transit modes if set
          if (profile?['preferred_transit'] != null) {
            final modes = (profile!['preferred_transit'] as String)
                .split(',')
                .map((m) => m.trim())
                .where((m) => m.isNotEmpty);
            if (modes.isNotEmpty) {
              _preferredModes.clear();
              _preferredModes.addAll(modes);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StitchProfileScreen] load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _getName());
    final phoneCtrl = TextEditingController(text: _getPhone());
    final localityCtrl = TextEditingController(text: _getLocality());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x240891B2),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Commuter Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModalField('FULL NAME', nameCtrl, Icons.person_rounded),
                const SizedBox(height: 14),
                _buildModalField('PHONE NUMBER', phoneCtrl, Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildModalField('HOME LOCALITY / CITY HUB', localityCtrl,
                    Icons.location_on_rounded),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveProfileChanges(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        locality: localityCtrl.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Profile Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0891B2)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfileChanges({
    required String name,
    required String phone,
    required String locality,
  }) async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.instance.updateUserProfile(
        fullName: name.isNotEmpty ? name : 'Aarav Patel',
        phone: phone.isNotEmpty ? phone : '9879044120',
        locality: locality.isNotEmpty ? locality : 'Ahmedabad',
        preferredTransit: _preferredModes.join(', '),
      );
      if (mounted) {
        setState(() {
          _profile = res['profile'] ?? SupabaseService.instance.currentUserProfile;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF10B981)),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Profile details updated successfully',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out of PRAVHA?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'You will be redirected to the sign in page. Your offline tickets and local history remain safe.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.instance.logoutUser();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      'Signed out successfully',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                widget.onLoggedOut();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getName() =>
      _profile?['full_name']?.toString().isNotEmpty == true
          ? _profile!['full_name']
          : 'Aarav Patel';

  String _getPhone() =>
      _profile?['phone']?.toString().isNotEmpty == true
          ? _profile!['phone']
          : '+91 98790 44120';

  String _getLocality() =>
      _profile?['locality']?.toString().isNotEmpty == true
          ? _profile!['locality']
          : 'SG Highway, Ahmedabad';


  String _getCommuterUid() {
    final rawId = _profile?['id']?.toString() ?? 'PRV20268841AHM';
    final clean = rawId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (clean.length > 8) {
      return 'PRV-${clean.substring(0, 4)}-${clean.substring(4, 8)}';
    }
    return 'PRV-2026-8841-AHM';
  }

  String _getInitials() {
    final name = _getName().trim();
    if (name.isEmpty) return 'A';
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const primaryTextColor = Color(0xFF0F172A);
    const secondaryTextColor = Color(0xFF64748B);
    const brandCyan = Color(0xFF0891B2);
    const emeraldGreen = Color(0xFF10B981);
    const brandPillBorder = Color(0xFFA5F3FC);

    final name = _getName();
    final phone = _getPhone();
    final locality = _getLocality();
    final commuterUid = _getCommuterUid();
    final initials = _getInitials();

    return StitchBackground(
      isDarkMode: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        child: LinearProgressIndicator(
                          minHeight: 2.5,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(brandCyan),
                        ),
                      ),
                    ),

                  // 1. TOP APP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      Tooltip(
                        message: 'Back',
                        child: GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: brandPillBorder,
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x120891B2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: primaryTextColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Brand Pill
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: brandPillBorder,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x100891B2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'PRAVHA PROFILE',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: primaryTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Switch Account / Login button
                      Tooltip(
                        message: 'Switch / Login with Another Account',
                        child: GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFEFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: brandPillBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.switch_account_rounded,
                                  size: 15,
                                  color: brandCyan,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Switch',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: brandCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. HERO COMMUTER CARD
                  StitchGlassCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(20),
                    hasCyanGlow: true,
                    borderColor: const Color(0xFFA5F3FC),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Row with Edit button
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0891B2),
                                    Color(0xFF06B6D4),
                                    Color(0xFF0E7490),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x3D0891B2),
                                    blurRadius: 18,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFA5F3FC),
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: brandCyan,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Name & Verified Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: primaryTextColor,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: brandCyan,
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Phone Number
                        Text(
                          phone,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Locality Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: brandCyan,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                locality,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // UID Strip with Copy Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COMMUTER TRANSIT ID',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    commuterUid,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: commuterUid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF0F172A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      content: Text(
                                        'Transit UID copied: $commuterUid',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFEFF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFA5F3FC),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: brandCyan,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Copy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: brandCyan,
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

                  const SizedBox(height: 16),

                  // 3. COMMUTER IMPACT & STATS
                  Text(
                    'COMMUTER STATS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.directions_transit_filled_rounded,
                          iconColor: const Color(0xFF0891B2),
                          title: 'Trips Taken',
                          value: '${_pastJourneysCount > 0 ? _pastJourneysCount + 12 : 18}',
                          subText: 'This Month',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.stars_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Green Points',
                          value: '420 pts',
                          subText: 'Redeem Passes',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. TRANSIT PASS STATUS (Active or Not Taken)
                  Text(
                    'SMART TRANSIT PASS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  StitchGlassCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(16),
                    borderColor: const Color(0xFFE2E8F0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _activePass != null
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _activePass != null
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Icon(
                                _activePass != null
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _activePass != null
                                    ? emeraldGreen
                                    : const Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _activePass != null
                                        ? (_activePass!['pass_title'] ?? 'Active Transit Pass')
                                        : 'Transit Pass',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    _activePass != null
                                        ? 'Active & verified for transit'
                                        : 'Not Taken',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _activePass != null
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _activePass != null
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _activePass != null
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 13,
                                    color: _activePass != null
                                        ? emeraldGreen
                                        : const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _activePass != null ? 'Active' : 'Not Taken',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: _activePass != null
                                          ? emeraldGreen
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: widget.onNavigateToPasses,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _activePass != null
                                      ? 'View Digital Pass'
                                      : 'Get or Buy Pass',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: brandCyan,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: brandCyan,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ACCOUNT ACTIONS
                  Text(
                    'ACCOUNT & SECURITY',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  StitchGlassCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderColor: const Color(0xFFE2E8F0),
                    child: Column(
                      children: [
                        _buildAccountActionTile(
                          icon: Icons.edit_note_rounded,
                          iconColor: brandCyan,
                          title: 'Edit Commuter Details',
                          subTitle: 'Update name, phone number, and home hub',
                          onTap: _showEditProfileDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildAccountActionTile(
                          icon: Icons.switch_account_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Switch Account / Login',
                          subTitle: 'Connect with a different commuter phone',
                          onTap: widget.onNavigateToLogin,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildAccountActionTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFEF4444),
                          title: 'Sign Out',
                          subTitle: 'Sign out from this device',
                          onTap: _confirmLogout,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 8. BACK TO TRANSIT MAP / HOME BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.onNavigateToHome,
                      icon: const Icon(Icons.explore_rounded, size: 18),
                      label: Text(
                        'Return to Transit Search',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subText,
  }) {
    return StitchGlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: const Color(0xFFE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            subText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAccountActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subTitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
