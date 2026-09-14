import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';
import '../config/transit_map_config.dart';

class StitchRouteScreen extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final String? focusLocation;
  final String? focusIncident;
  final VoidCallback? onClearFocus;

  const StitchRouteScreen({
    super.key,
    required this.onNavigateToHome,
    required this.onNavigateToAskRoute,
    required this.onNavigateToPasses,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.focusLocation,
    this.focusIncident,
    this.onClearFocus,
  });

  @override
  State<StitchRouteScreen> createState() => _StitchRouteScreenState();
}

class _StitchRouteScreenState extends State<StitchRouteScreen>
    with SingleTickerProviderStateMixin {
  bool _isRouteLegs = true;
  bool _hapticOn = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showGoogleMapsConfigModal(BuildContext context) {
    final dark = widget.isDarkMode;
    final controller = TextEditingController(text: TransitMapConfig.googleMapsApiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Maps API Setup',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Configure for live satellite & corridor rendering',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'GOOGLE MAPS API KEY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF38BDF8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: dark
                        ? const Color(0x38FFFFFF)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    color: dark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can also set this permanently in lib/config/transit_map_config.dart',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: dark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      TransitMapConfig.setApiKey(controller.text);
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          TransitMapConfig.hasGoogleMapsApiKey
                              ? 'Google Maps API Key activated!'
                              : 'API Key cleared',
                        ),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF00354A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save & Apply API Key',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                      // TOP BAR: Transit AI GTFS Synced + Moon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xB30F172A) : const Color(0xE6FFFFFF),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: dark ? const Color(0x38FFFFFF) : const Color(0x40FFFFFF),
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
                                    Icons.directions_bus_rounded,
                                    color: Color(0xFF00354A),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Transit AI',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: dark ? Colors.white : const Color(0xFF0F172A),
                                        height: 1.1,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF56E5A9),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'GTFS Synced',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 8,
                                            color: const Color(0xFF10B981),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Top Right Actions: Profile Button + Theme Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StitchProfileButton(
                                isDarkMode: dark,
                                onTap: widget.onNavigateToProfile,
                              ),
                              const SizedBox(width: 8),
                              StitchThemeToggleButton(
                                isDarkMode: dark,
                                onToggleTheme: widget.onToggleTheme,
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (widget.focusLocation != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x33EF4444), Color(0x22DC2626)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40EF4444),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFF87171),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'LIVE INCIDENT MAP FOCUS',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFFF87171),
                                          ),
                                        ),
                                        if (widget.onClearFocus != null)
                                          GestureDetector(
                                            onTap: widget.onClearFocus,
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Colors.white70,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.focusLocation!,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (widget.focusIncident != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.focusIncident!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFFFCA5A5),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.alt_route_rounded,
                                          size: 13,
                                          color: Color(0xFF38BDF8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Detour active • Avoiding ground-level corridor',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF38BDF8),
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
                      ],

                      const SizedBox(height: 12),

                      // SEGMENTED PILL SWITCHER: Route Legs vs Explore Map
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
                                onTap: () => setState(() => _isRouteLegs = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isRouteLegs
                                        ? const Color(0x4D38BDF8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: _isRouteLegs
                                        ? Border.all(
                                            color: const Color(0xFF38BDF8),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.alt_route_rounded,
                                        size: 14,
                                        color: Color(0xFF38BDF8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Route Legs',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isRouteLegs = false),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.map_outlined,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Explore Map',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF94A3B8),
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

                      if (_isRouteLegs) ...[
                        // 1. CORRIDOR POLYLINE PREVIEW CARD
                        StitchGlassCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // Header: Haptic switch + Live Corridor
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.show_chart_rounded,
                                        size: 16,
                                        color: Color(0xFF38BDF8),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Corridor Polyline',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _hapticOn = !_hapticOn),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0x3306B6D4),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF06B6D4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.vibration_rounded,
                                              size: 11,
                                              color: Color(0xFF38BDF8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _hapticOn
                                                  ? 'Haptic: ON'
                                                  : 'Haptic: OFF',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF38BDF8),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: _hapticOn
                                                    ? const Color(0xFF38BDF8)
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0x2638BDF8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Live',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Map Vector Canvas from Stitch
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF060E20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0x26FFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    // Custom Paint Grid & Vector Polyline
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: Size.infinite,
                                          painter: _StitchCorridorPainter(
                                            progress: _pulseController.value,
                                          ),
                                        );
                                      },
                                    ),

                                    // Origin Label Badge
                                    Positioned(
                                      top: 14,
                                      left: 12,
                                      child: _buildMapNodeLabel(
                                        '1. Sola Bhagwat (Origin)',
                                        const Color(0xFF38BDF8),
                                      ),
                                    ),

                                    // Live Bus Telemetry Marker & Pill
                                    Positioned(
                                      top: 36,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Bus 9U • 39 km/h Cruise',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.equalizer_rounded,
                                              size: 11,
                                              color: Color(0xFF56E5A9),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Transfer Hub Label
                                    Positioned(
                                      top: 92,
                                      left: 110,
                                      child: _buildMapNodeLabel(
                                        'Shivranjani Hub (Transfer)',
                                        const Color(0xFFFFB95F),
                                      ),
                                    ),

                                    // Destination Hub Label
                                    Positioned(
                                      bottom: 12,
                                      right: 14,
                                      child: _buildMapNodeLabel(
                                        '3. Iskcon Cross Rd',
                                        const Color(0xFFF43F5E),
                                      ),
                                    ),

                                    // Map Controls (Crosshairs & Fullscreen)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: const Color(0xB30F172A),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.my_location_rounded,
                                              size: 14,
                                              color: Color(0xFF38BDF8),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: const Color(0xB30F172A),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.fullscreen_rounded,
                                              size: 16,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. FASTEST CORRIDOR SUMMARY CARD
                      StitchGlassCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Fastest Corridor badge + Times + Fare
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF56E5A9)
                                        .withValues(alpha: 0.2),
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
                                        'Fastest Corridor',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF56E5A9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '08:30 AM — 08:58 AM',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                Text(
                                  '₹9.00',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF56E5A9),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Sola Bhagwat → Iskcon Cross Rd',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Multimodal Route Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTransitChip(
                                    title: 'BRTS 9U',
                                    sub: '₹5.00 • 18m',
                                    color: const Color(0xFF38BDF8),
                                    icon: Icons.directions_bus_rounded,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_forward_rounded,
                                        size: 14, color: Color(0xFF64748B)),
                                  ),
                                  _buildTransitChip(
                                    title: 'Walk 120m',
                                    sub: 'Shivranjani Hub',
                                    color: const Color(0xFFFFB95F),
                                    icon: Icons.directions_walk_rounded,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_forward_rounded,
                                        size: 14, color: Color(0xFF64748B)),
                                  ),
                                  _buildTransitChip(
                                    title: 'BRTS 8D',
                                    sub: '₹4.00 • 7m',
                                    color: const Color(0xFF3B82F6),
                                    icon: Icons.directions_bus_rounded,
                                  ),
                                ],
                              ),
                            ),

                            const Divider(
                                color: Color(0x26FFFFFF), height: 22),

                            // Metric Counters Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetric(
                                    'DURATION', '28 min', Icons.schedule_rounded),
                                _buildMetric(
                                    'DISTANCE', '11 km', Icons.route_rounded),
                                _buildMetric('UNIFIED FARE', '₹9.00',
                                    Icons.currency_rupee_rounded),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3. ROUTE LEGS BREAKDOWN CARD
                      StitchGlassCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.alt_route_rounded,
                                        size: 16, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Route Legs Breakdown',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0x3338BDF8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Total: ₹9.00',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Leg 1: Sola Bhagwat -> Shivranjani
                            _buildLegCard(
                              badge: 'L1',
                              badgeColor: const Color(0xFF38BDF8),
                              title: 'Sola Bhagwat → Shivranjani',
                              routeTag: 'BRTS 9U',
                              fare: '₹5.00',
                              timing: '08:30 AM — 08:48 AM • 18 min • 7 stops',
                              status: 'Platform 2 • Live GPS on-time',
                              highlight: 'Next in 3 min',
                            ),

                            const SizedBox(height: 8),

                            // Transfer Concourse
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB95F)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFB95F)
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB95F)
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.directions_walk_rounded,
                                      size: 16,
                                      color: Color(0xFFFFB95F),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Shivranjani Hub Transfer',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFFFB95F),
                                          ),
                                        ),
                                        Text(
                                          '08:48 AM — 08:51 AM • 3 min walk • 120m concourse',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB95F)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Free Transfer',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFFB95F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Leg 2: Shivranjani -> Iskcon
                            _buildLegCard(
                              badge: 'L2',
                              badgeColor: const Color(0xFF3B82F6),
                              title: 'Shivranjani → Iskcon Cross Rd',
                              routeTag: 'BRTS 8D',
                              fare: '₹4.00',
                              timing: '08:51 AM — 08:58 AM • 7 min • 3 stops',
                              status: 'Platform 4B • AC Electric Fleet',
                              highlight: 'Synced connection',
                            ),

                            const SizedBox(height: 12),

                            // Actions Row: Directions & Platform Map
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0x2EFFFFFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.turn_right_rounded,
                                          size: 15,
                                          color: Color(0xFF38BDF8),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Directions',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0x2EFFFFFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.transfer_within_a_station_rounded,
                                          size: 15,
                                          color: Color(0xFFFFB95F),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Platform Map',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4. CTA BUTTON: Book Instant Ticket (₹9.00)
                      GestureDetector(
                        onTap: widget.onNavigateToWallet,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF56E5A9)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x5538BDF8),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                size: 22,
                                color: Color(0xFF00354A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Book Instant Ticket (₹9.00)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF00354A),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildExploreMapView(dark),
                    ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM DOCK (ROUTE tab active - Index 1)
          StitchBottomDock(
            activeIndex: 1,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 0) {
                widget.onNavigateToHome();
              } else if (index == 2) {
                widget.onNavigateToAskRoute();
              } else if (index == 3) {
                widget.onNavigateToPasses();
              } else if (index == 4) {
                widget.onNavigateToWallet();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapNodeLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xB30F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTransitChip({
    required String title,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required String routeTag,
    required String fare,
    required String timing,
    required String status,
    required String highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x26FFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  routeTag,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                fare,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF56E5A9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timing,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                highlight,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreMapView(bool dark) {
    final primaryTextColor = dark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final cardBg =
        dark ? const Color(0xB30F172A) : const Color(0xEBFFFFFF);
    final cardBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0x80FFFFFF);

    return Column(
      children: [
        // 1. Google Maps Integration & Readiness Banner
        GestureDetector(
          onTap: () => _showGoogleMapsConfigModal(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0x330284C7)
                  : const Color(0x200284C7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF38BDF8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Google Maps API Ready',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TransitMapConfig.hasGoogleMapsApiKey
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              TransitMapConfig.hasGoogleMapsApiKey
                                  ? 'Key Active'
                                  : 'Tap to Setup Key',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: TransitMapConfig.hasGoogleMapsApiKey
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TransitMapConfig.hasGoogleMapsApiKey
                            ? 'Google Maps API key is configured and active. Tap to modify.'
                            : 'Tap here to configure or paste your Google Maps API Key.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Interactive Map Canvas Card
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.4 : 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Interactive Vector Polyline Canvas
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _StitchCorridorPainter(
                          progress: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),

                // Map Layer Chips at Top
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xE60F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0x38FFFFFF), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers_rounded,
                                size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              'Corridor Polyline Map',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xE60F172A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0x38FFFFFF), width: 0.8),
                            ),
                            child: const Icon(Icons.add,
                                size: 15, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xE60F172A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0x38FFFFFF), width: 0.8),
                            ),
                            child: const Icon(Icons.my_location_rounded,
                                size: 14, color: Color(0xFF38BDF8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Station Pins Overlay
                Positioned(
                  left: 20,
                  top: 75,
                  child: _buildMapNodeLabel(
                      'Sola Bhagwat (Origin)', const Color(0xFF38BDF8)),
                ),
                Positioned(
                  left: 120,
                  top: 155,
                  child: _buildMapNodeLabel(
                      'Shivranjani (Transfer)', const Color(0xFFFFB95F)),
                ),
                Positioned(
                  right: 20,
                  bottom: 75,
                  child: _buildMapNodeLabel(
                      'Iskcon Circle (Dest)', const Color(0xFFF43F5E)),
                ),

                // GPS Telemetry Bar at Bottom
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xEE060E20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0x2EFFFFFF), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '23.0827° N, 72.5284° E • GIFT Corridor',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live GPS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // CTA BUTTON: Book Instant Ticket
        GestureDetector(
          onTap: widget.onNavigateToWallet,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF56E5A9)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5538BDF8),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 22,
                  color: Color(0xFF00354A),
                ),
                const SizedBox(width: 8),
                Text(
                  'Book Instant Ticket (₹9.00)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00354A),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StitchCorridorPainter extends CustomPainter {
  final double progress;
  _StitchCorridorPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1838BDF8)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final p1 = Offset(size.width * 0.15, size.height * 0.30);
    final pTransfer = Offset(size.width * 0.52, size.height * 0.54);
    final p2 = Offset(size.width * 0.88, size.height * 0.72);

    // Cyan leg (p1 -> pTransfer)
    final pathCyan = Path();
    pathCyan.moveTo(p1.dx, p1.dy);
    pathCyan.cubicTo(
      size.width * 0.28,
      size.height * 0.32,
      size.width * 0.38,
      size.height * 0.52,
      pTransfer.dx,
      pTransfer.dy,
    );

    // Glow underlay
    canvas.drawPath(
      pathCyan,
      Paint()
        ..color = const Color(0x6600F5FF)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      pathCyan,
      Paint()
        ..color = const Color(0xFF00F5FF)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Blue leg (pTransfer -> p2)
    final pathBlue = Path();
    pathBlue.moveTo(pTransfer.dx + 12, pTransfer.dy);
    pathBlue.cubicTo(
      size.width * 0.65,
      size.height * 0.54,
      size.width * 0.75,
      size.height * 0.70,
      p2.dx,
      p2.dy,
    );

    canvas.drawPath(
      pathBlue,
      Paint()
        ..color = const Color(0x663B82F6)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      pathBlue,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Nodes
    _drawRingNode(canvas, p1, const Color(0xFF00F5FF));
    _drawRingNode(canvas, pTransfer, const Color(0xFFFFB95F));
    _drawRingNode(canvas, Offset(pTransfer.dx + 12, pTransfer.dy),
        const Color(0xFFFFB95F));
    _drawRingNode(canvas, p2, const Color(0xFFF43F5E));

    // Vehicle Marker along pathCyan
    final metrics = pathCyan.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final tangent =
          metric.getTangentForOffset(metric.length * (progress % 1.0));
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          7,
          Paint()
            ..color = const Color(0xFF00F5FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          tangent.position,
          4,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  void _drawRingNode(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(
      pos,
      5.5,
      Paint()
        ..color = const Color(0xFF060E20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      5.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _StitchCorridorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
