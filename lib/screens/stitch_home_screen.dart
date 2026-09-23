import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_profile_button.dart';
import '../widgets/stitch_place_autocomplete_dropdown.dart';
import '../services/transit_place_service.dart';
import '../core/storage/local_transit_vault.dart';

class StitchHomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToRouteDetails;
  final void Function(String origin, String destination)? onSearchRoute;
  final VoidCallback onNavigateToAskRoute;
  final VoidCallback onNavigateToPasses;
  final VoidCallback onNavigateToWallet;
  final VoidCallback onNavigateToProfile;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;
  final VoidCallback? onReplaySplash;

  const StitchHomeScreen({
    super.key,
    required this.onNavigateToRouteDetails,
    this.onSearchRoute,
    required this.onNavigateToAskRoute,
    required this.onNavigateToPasses,
    required this.onNavigateToWallet,
    required this.onNavigateToProfile,
    this.onToggleTheme,
    required this.isDarkMode,
    this.onReplaySplash,
  });

  @override
  State<StitchHomeScreen> createState() => _StitchHomeScreenState();
}

class _StitchHomeScreenState extends State<StitchHomeScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destFocusNode = FocusNode();

  List<TransitPlaceSuggestion> _originSuggestions = [];
  List<TransitPlaceSuggestion> _destSuggestions = [];
  bool _showOriginDropdown = false;
  bool _showDestDropdown = false;
  List<Map<String, dynamic>> _pastJourneys = [];

  // Quick suggestions for easy one-tap input
  final List<String> _quickStations = [
    'Sola Bhagwat',
    'Iskcon Cross Road',
    'Kalupur Railway Station',
    'GIFT City Tower',
    'Shivranjani',
    'Vastrapur',
  ];

  @override
  void initState() {
    super.initState();
    _loadPastJourneys();

    _originFocusNode.addListener(() {
      if (_originFocusNode.hasFocus) {
        _fetchOriginSuggestions(_originController.text);
        setState(() {
          _showOriginDropdown = true;
          _showDestDropdown = false;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_originFocusNode.hasFocus) {
            setState(() => _showOriginDropdown = false);
          }
        });
      }
    });

    _destFocusNode.addListener(() {
      if (_destFocusNode.hasFocus) {
        _fetchDestSuggestions(_destController.text);
        setState(() {
          _showDestDropdown = true;
          _showOriginDropdown = false;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_destFocusNode.hasFocus) {
            setState(() => _showDestDropdown = false);
          }
        });
      }
    });
  }

  Future<void> _loadPastJourneys() async {
    final list = await LocalTransitVault.instance.getPastJourneys();
    if (mounted) {
      setState(() {
        _pastJourneys = list;
      });
    }
  }

  Future<void> _fetchOriginSuggestions(String query) async {
    final list = await TransitPlaceService.instance.getSuggestions(query);
    if (mounted) {
      setState(() {
        _originSuggestions = list;
        _showOriginDropdown = true;
      });
    }
  }

  Future<void> _fetchDestSuggestions(String query) async {
    final list = await TransitPlaceService.instance.getSuggestions(query);
    if (mounted) {
      setState(() {
        _destSuggestions = list;
        _showDestDropdown = true;
      });
    }
  }

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
    _originFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dark = false;

    const primaryTextColor = Color(0xFF0F172A);
    const secondaryTextColor = Color(0xFF64748B);
    const brandPillBg = Colors.white;
    const brandPillBorder = Color(0xFFA5F3FC);
    const inputBg = Color(0xFFF8FAFC);
    const inputBorder = Color(0xFFE2E8F0);

    return StitchBackground(
      isDarkMode: false,
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
                          GestureDetector(
                            onTap: widget.onReplaySplash,
                            child: Container(
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
                                    color: const Color(0xFF0891B2).withValues(alpha: 0.10),
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
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
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
                                    'PRAVHA',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
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
                          ),

                          // Top Right Actions: Profile Button
                          StitchProfileButton(
                            isDarkMode: dark,
                            onTap: widget.onNavigateToProfile,
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
                                  color: Color(0xFF0891B2),
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
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  children: [
                                    // From Origin Editable TextField
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _originFocusNode.requestFocus(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: inputBg,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _originFocusNode.hasFocus
                                                ? const Color(0xFF0891B2)
                                                : inputBorder,
                                            width: _originFocusNode.hasFocus ? 1.5 : 1,
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
                                                    'FROM ORIGIN',
                                                    style:
                                                        GoogleFonts.jetBrainsMono(
                                                      fontSize: 8.5,
                                                      color: const Color(0xFF10B981),
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  TextField(
                                                    controller: _originController,
                                                    focusNode: _originFocusNode,
                                                    onChanged: (val) {
                                                      setState(() {});
                                                      _fetchOriginSuggestions(val);
                                                    },
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: primaryTextColor,
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      hintText:
                                                          'Enter origin stop (e.g. Sola, Gota)',
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
                                            // Clear origin button if not empty
                                            if (_originController.text.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _originController.clear();
                                                    _showOriginDropdown = false;
                                                  });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.only(right: 6),
                                                  child: Icon(
                                                    Icons.cancel_rounded,
                                                    size: 16,
                                                    color: secondaryTextColor,
                                                  ),
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
                                                  color: Color(0xFF0891B2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Origin Autocomplete Suggestions Dropdown
                                    if (_showOriginDropdown && _originSuggestions.isNotEmpty)
                                      StitchPlaceAutocompleteDropdown(
                                        suggestions: _originSuggestions,
                                        isDarkMode: dark,
                                        onSelect: (s) {
                                          setState(() {
                                            _originController.text = s.name;
                                            _showOriginDropdown = false;
                                          });
                                          _destFocusNode.requestFocus();
                                          _fetchDestSuggestions(_destController.text);
                                        },
                                      ),

                                    const SizedBox(height: 10),

                                    // To Destination Editable TextField
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _destFocusNode.requestFocus(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: inputBg,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _destFocusNode.hasFocus
                                                ? const Color(0xFF0891B2)
                                                : inputBorder,
                                            width: _destFocusNode.hasFocus ? 1.5 : 1,
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
                                                    'TO DESTINATION',
                                                    style:
                                                        GoogleFonts.jetBrainsMono(
                                                      fontSize: 8.5,
                                                      color: const Color(0xFFF43F5E),
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  TextField(
                                                    controller: _destController,
                                                    focusNode: _destFocusNode,
                                                    onChanged: (val) {
                                                      setState(() {});
                                                      _fetchDestSuggestions(val);
                                                    },
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: primaryTextColor,
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      hintText:
                                                          'Enter destination stop (e.g. Iskcon)',
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
                                                    _showDestDropdown = false;
                                                  });
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.only(right: 6),
                                                  child: Icon(
                                                    Icons.cancel_rounded,
                                                    size: 16,
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 32),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Destination Autocomplete Suggestions Dropdown
                                    if (_showDestDropdown && _destSuggestions.isNotEmpty)
                                      StitchPlaceAutocompleteDropdown(
                                        suggestions: _destSuggestions,
                                        isDarkMode: dark,
                                        onSelect: (s) {
                                          setState(() {
                                            _destController.text = s.name;
                                            _showDestDropdown = false;
                                          });
                                          _destFocusNode.unfocus();
                                        },
                                      ),
                                  ],
                                ),

                                // Floating Swap Button on the right
                                Positioned(
                                  right: 10,
                                  top: 40,
                                  child: GestureDetector(
                                    onTap: _swap,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0891B2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0891B2)
                                                .withValues(alpha: 0.15),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.swap_vert_rounded,
                                        size: 20,
                                        color: Color(0xFF0891B2),
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
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      side: const BorderSide(
                                        color: Color(0xFFE2E8F0),
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
                              onTap: () {
                                if (widget.onSearchRoute != null) {
                                  widget.onSearchRoute!(
                                    _originController.text.trim(),
                                    _destController.text.trim(),
                                  );
                                } else {
                                  widget.onNavigateToRouteDetails();
                                }
                              },
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0891B2),
                                  borderRadius: BorderRadius.circular(23),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33FF6B00),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search Routes',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white,
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
                              colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x38FF6B00),
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
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Book Instant QR Ticket',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
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
                                        color: Color(0xFF0891B2),
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
                                    color: const Color(0xFFECFEFF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Recent Activity',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0891B2),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            if (_pastJourneys.isNotEmpty)
                              ..._pastJourneys.map((j) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildJourneyItem(
                                    dark: false,
                                    icon: Icons.directions_bus_rounded,
                                    iconBg: const Color(0xFF0891B2),
                                    title: j['title'] ?? 'Corridor Commute',
                                    fare: j['fare'] ?? '₹9.00',
                                    badgeText: j['badgeText'] ?? 'Completed',
                                    timeText: j['timeText'] ?? 'Recent',
                                    onRebook: widget.onNavigateToWallet,
                                  ),
                                );
                              })
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0891B2)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.departure_board_rounded,
                                        color: Color(0xFF0891B2),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No past journeys recorded',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Search a corridor above or pick a popular route to begin:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: secondaryTextColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _buildPopularRoutePill(
                                          'Sola ➔ Iskcon',
                                          'Sola Bhagwat',
                                          'Iskcon Cross Road',
                                          false,
                                        ),
                                        _buildPopularRoutePill(
                                          'Gota ➔ Shivranjani',
                                          'Gota Cross Road',
                                          'Shivranjani',
                                          false,
                                        ),
                                        _buildPopularRoutePill(
                                          'Kalupur ➔ Vastrapur',
                                          'Kalupur Railway Station',
                                          'Vastrapur Lake',
                                          false,
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
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM DOCK (SEARCH tab active - Index 0)
          StitchBottomDock(
            activeIndex: 0,
            isDarkMode: false,
            onTabSelected: (index) {
              if (index == 1) {
                widget.onNavigateToRouteDetails();
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

  Widget _buildPopularRoutePill(String label, String origin, String dest, bool dark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _originController.text = origin;
          _destController.text = dest;
        });
        if (widget.onSearchRoute != null) {
          widget.onSearchRoute!(origin, dest);
        } else {
          widget.onNavigateToRouteDetails();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFF0891B2)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
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
    const itemBg = Color(0xFFF8FAFC);
    const itemBorder = Color(0xFFE2E8F0);
    const itemTitleColor = Color(0xFF0F172A);
    const itemSubColor = Color(0xFF64748B);

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
                  color: iconBg.withValues(alpha: 0.15),
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
                  color: const Color(0xFF0891B2),
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
                          color: const Color(0xFFECFEFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0891B2),
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
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF0891B2),
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
