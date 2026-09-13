import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';

class StitchHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToRouteDetails;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const StitchHomeScreen({
    super.key,
    required this.onNavigateToRouteDetails,
    required this.onNavigateToPasses,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<StitchHomeScreen> createState() => _StitchHomeScreenState();
}

class _StitchHomeScreenState extends State<StitchHomeScreen> {
  final TextEditingController _originController =
      TextEditingController(text: 'Sola Bhagwat (BRTS Hub)');
  final TextEditingController _destController =
      TextEditingController(text: 'Iskcon Cross Road');

  // Quick suggestions for easy one-tap input
  final List<String> _quickStations = [
    'Sola Bhagwat',
    'Iskcon Cross Road',
    'Kalupur Railway Station',
    'GIFT City Tower',
    'Shivranjani',
    'Vastrapur',
  ];

  void _swap() {
    setState(() {
      final t = _originController.text;
      _originController.text = _destController.text;
      _destController.text = t;
    });
  }

  void _setCurrentLocation() {
    setState(() {
      _originController.text = 'Current Location (GPS)';
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
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
    final inputBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9);
    final inputBorder =
        dark ? const Color(0x38FFFFFF) : const Color(0xFFCBD5E1);

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
                      // TOP BAR: Brand Pill + Profile Button + Theme Toggle Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                Text(
                                  'Transit AI',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Top Right Actions: Profile Button + Theme Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Profile Icon leading to Login/Sign Up
                              StitchProfileButton(
                                isDarkMode: dark,
                                onTap: widget.onNavigateToProfile,
                              ),
                              const SizedBox(width: 8),

                              // Dynamic Theme Toggle
                              StitchThemeToggleButton(
                                isDarkMode: dark,
                                onToggleTheme: widget.onToggleTheme,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 1. SEARCH YOUR ROUTE CARD (Interactive Editable Inputs)
                      StitchGlassCard(
                        isDarkMode: dark,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.alt_route_rounded,
                                  size: 18,
                                  color: Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Search your Route',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Interactive Inputs with Connecting Rail and Swap Button
                            Stack(
                              children: [
                                Column(
                                  children: [
                                    // From Origin Editable TextField
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
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
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'From Origin',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    color: secondaryTextColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                TextField(
                                                  controller: _originController,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: primaryTextColor,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    hintText:
                                                        'Enter origin stop or landmark',
                                                    hintStyle: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 12,
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // GPS My Location Action
                                          Tooltip(
                                            message: 'Use Current Location',
                                            child: GestureDetector(
                                              onTap: _setCurrentLocation,
                                              child: const Icon(
                                                Icons.my_location_rounded,
                                                size: 18,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // To Destination Editable TextField
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
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
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF43F5E)
                                                  .withValues(alpha: 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: Color(0xFFF43F5E),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'To Destination',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 9,
                                                    color: secondaryTextColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                TextField(
                                                  controller: _destController,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: primaryTextColor,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    hintText:
                                                        'Enter destination stop or landmark',
                                                    hintStyle: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 12,
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Clear text button if not empty
                                          if (_destController.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _destController.clear();
                                                });
                                              },
                                              child: Icon(
                                                Icons.cancel_rounded,
                                                size: 16,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          const SizedBox(width: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Floating Swap Button on the right
                                Positioned(
                                  right: 28,
                                  top: 38,
                                  child: GestureDetector(
                                    onTap: _swap,
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? const Color(0xFF0F172A)
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0284C7),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.swap_vert_rounded,
                                        size: 20,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Quick Autocomplete Station Suggestions
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _quickStations.map((station) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                      side: BorderSide(
                                        color: dark
                                            ? const Color(0x2EFFFFFF)
                                            : const Color(0xFFCBD5E1),
                                        width: 0.8,
                                      ),
                                      label: Text(
                                        station,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _destController.text = station;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Search Routes CTA Button
                            GestureDetector(
                              onTap: widget.onNavigateToRouteDetails,
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF0284C7),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x3338BDF8),
                                      blurRadius: 12,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: dark
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search Routes',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: dark
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 2. BIG VIBRANT GRADIENT BUTTON: Book Instant Ticket (₹9.00)
                      GestureDetector(
                        onTap: widget.onNavigateToWallet,
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Book Instant Ticket (₹9.00)',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF00354A),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3. PAST JOURNEYS CARD
                      StitchGlassCard(
                        isDarkMode: dark,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                        color: Color(0xFF0284C7),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Past Journeys',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 15,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? const Color(0x26FFFFFF)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Recent Activity',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Journey Item 1: Sola Bhagwat -> Iskcon
                            _buildJourneyItem(
                              dark: dark,
                              icon: Icons.directions_bus_rounded,
                              iconBg: const Color(0xFF0284C7),
                              title: 'Sola Bhagwat → Iskcon Cross Road',
                              fare: '₹9.00',
                              badgeText: 'BRTS Line 9U',
                              timeText: 'Today, 08:30 AM',
                              onRebook: widget.onNavigateToWallet,
                            ),

                            const SizedBox(height: 12),

                            // Journey Item 2: Iskcon -> Shivranjani
                            _buildJourneyItem(
                              dark: dark,
                              icon: Icons.directions_bus_rounded,
                              iconBg: const Color(0xFFF59E0B),
                              title: 'Iskcon Cross Road → Shivranjani',
                              fare: '₹4.00',
                              badgeText: 'Feeder 8D',
                              timeText: 'Yesterday, 06:15 PM',
                              onRebook: widget.onNavigateToWallet,
                            ),

                            const SizedBox(height: 12),

                            // Journey Item 3: Kalupur -> Vastrapur
                            _buildJourneyItem(
                              dark: dark,
                              icon: Icons.subway_rounded,
                              iconBg: const Color(0xFF10B981),
                              title: 'Kalupur Railway Station → Vastrapur',
                              fare: '₹15.00',
                              badgeText: 'Metro Line 1',
                              timeText: '12 Oct, 10:15 AM',
                              onRebook: widget.onNavigateToWallet,
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

          // BOTTOM DOCK (SEARCH tab active - Index 0)
          StitchBottomDock(
            activeIndex: 0,
            isDarkMode: dark,
            onTabSelected: (index) {
              if (index == 1) {
                widget.onNavigateToRouteDetails();
              } else if (index == 2) {
                widget.onNavigateToPasses();
              } else if (index == 3) {
                widget.onNavigateToWallet();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyItem({
    required bool dark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String fare,
    required String badgeText,
    required String timeText,
    required VoidCallback onRebook,
  }) {
    final itemBg = dark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8FAFC);
    final itemBorder =
        dark ? const Color(0x26FFFFFF) : const Color(0xFFE2E8F0);
    final itemTitleColor = dark ? Colors.white : const Color(0xFF0F172A);
    final itemSubColor =
        dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: itemBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconBg, width: 1),
                ),
                child: Icon(icon, color: iconBg, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: itemTitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                fare,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0x33FFFFFF)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color:
                                dark ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                        'Completed',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: itemSubColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRebook,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rebook',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
