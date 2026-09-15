import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stitch_glass_card.dart';
import '../widgets/stitch_bottom_dock.dart';
import '../widgets/stitch_background.dart';
import '../widgets/stitch_theme_toggle_button.dart';
import '../widgets/stitch_profile_button.dart';
import '../widgets/stitch_place_autocomplete_dropdown.dart';
import '../config/transit_map_config.dart';
import '../services/google_directions_service.dart';
import '../services/supabase_service.dart';
import '../services/transit_place_service.dart';
import '../services/transit_gps_service.dart';

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
  final String? initialOrigin;
  final String? initialDestination;

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
    this.initialOrigin,
    this.initialDestination,
  });

  @override
  State<StitchRouteScreen> createState() => _StitchRouteScreenState();
}

class _StitchRouteScreenState extends State<StitchRouteScreen> {
  bool _isRouteLegs = true;
  bool _satelliteMode = false;
  String _mapScope = 'corridor'; // 'corridor' (tight on route), 'city' (Ahmedabad City), 'metro' (Regional Metro)

  TransitGpsLocation? _currentGps;
  StreamSubscription<TransitGpsLocation>? _gpsSubscription;

  late final TransformationController _corridorMapController;
  late final TransformationController _exploreMapController;

  late TextEditingController _originController;
  late TextEditingController _destController;
  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destFocusNode = FocusNode();

  List<TransitPlaceSuggestion> _originSuggestions = [];
  List<TransitPlaceSuggestion> _destSuggestions = [];
  bool _showOriginDropdown = false;
  bool _showDestDropdown = false;

  TransitRouteResult? _currentRoute;
  bool _isLoadingRoute = false;

  void _zoomIn(TransformationController controller) {
    final matrix = controller.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    controller.value = matrix;
  }

  void _zoomOut(TransformationController controller) {
    final matrix = controller.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    controller.value = matrix;
  }

  void _resetZoom(TransformationController controller) {
    controller.value = Matrix4.identity();
  }

  Future<void> _locateUser() async {
    final loc = await TransitGpsService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentGps = loc;
      _mapScope = 'corridor';
    });
    _corridorMapController.value = Matrix4.identity();
    _exploreMapController.value = Matrix4.identity();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: Color(0xFF00E5FF), size: 16),
            const SizedBox(width: 8),
            Text(
              'Live GPS: ${loc.formattedCoords} (${loc.accuracyLabel})',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xEE0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openFullScreenMap(BuildContext context, bool dark) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _FullScreenMapViewer(
          route: _currentRoute,
          dark: dark,
          initialSatelliteMode: _satelliteMode,
          initialGps: _currentGps,
          initialScope: _mapScope,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _corridorMapController = TransformationController();
    _exploreMapController = TransformationController();

    final defaultOrigin = widget.initialOrigin?.trim() ?? '';
    final defaultDest = widget.initialDestination?.trim() ?? '';

    _originController = TextEditingController(text: defaultOrigin);
    _destController = TextEditingController(text: defaultDest);

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

    if (defaultOrigin.isNotEmpty && defaultDest.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRoute();
      });
    }

    // Initialize live GPS tracking
    TransitGpsService.instance.getCurrentLocation().then((loc) {
      if (mounted) setState(() => _currentGps = loc);
    });
    _gpsSubscription = TransitGpsService.instance.streamLocation().listen((loc) {
      if (mounted) setState(() => _currentGps = loc);
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _corridorMapController.dispose();
    _exploreMapController.dispose();
    _originController.dispose();
    _destController.dispose();
    _originFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StitchRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialOrigin != null && widget.initialOrigin != oldWidget.initialOrigin) ||
        (widget.initialDestination != null && widget.initialDestination != oldWidget.initialDestination)) {
      if (widget.initialOrigin?.isNotEmpty == true) {
        _originController.text = widget.initialOrigin!;
      }
      if (widget.initialDestination?.isNotEmpty == true) {
        _destController.text = widget.initialDestination!;
      }
      if (_originController.text.isNotEmpty && _destController.text.isNotEmpty) {
        _fetchRoute();
      }
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

  /// Triggers route search: Checks Supabase cache first; on miss, queries
  /// Google Directions API in DRIVING mode and stores polyline in Supabase.
  Future<void> _fetchRoute() async {
    final origin = _originController.text.trim();
    final dest = _destController.text.trim();
    if (origin.isEmpty || dest.isEmpty) return;

    setState(() {
      _isLoadingRoute = true;
      _showOriginDropdown = false;
      _showDestDropdown = false;
    });

    try {
      final route = await SupabaseService.instance.searchAndCacheRoute(
        origin: origin,
        destination: dest,
      );

      if (mounted) {
        setState(() {
          _currentRoute = route;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('[StitchRouteScreen] Error fetching route: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _swapStops() {
    setState(() {
      final temp = _originController.text;
      _originController.text = _destController.text;
      _destController.text = temp;
    });
    if (_originController.text.isNotEmpty && _destController.text.isNotEmpty) {
      _fetchRoute();
    }
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
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar
                      _buildTopBar(dark),

                      if (widget.focusLocation != null) ...[
                        const SizedBox(height: 10),
                        _buildIncidentFocusCard(),
                      ],

                      const SizedBox(height: 12),

                      // Dynamic Route Search Card (Trigger live Google Maps Driving Route)
                      _buildRouteSearchCard(dark),

                      const SizedBox(height: 12),

                      // Segmented Switcher: Route Legs vs Explore Map
                      _buildSegmentedSwitcher(),

                      const SizedBox(height: 12),

                      if (_isRouteLegs) ...[
                        // 1. Interactive Google Maps & Street Polyline Canvas
                        _buildCorridorPolylineCard(dark),

                        const SizedBox(height: 12),

                        // 2. Real Route Summary Card (Dynamic Distance, Time, Fare)
                        _buildRouteSummaryCard(dark),

                        const SizedBox(height: 12),

                        // 3. Dynamic Route Legs & Street Navigation Steps
                        _buildRouteLegsBreakdownCard(dark),

                        const SizedBox(height: 12),

                        // 4. CTA Button: Book Instant Ticket
                        _buildBookTicketCta(),
                      ] else ...[
                        _buildExploreMapView(dark),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Dock (ROUTE tab active - Index 1)
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

  Widget _buildTopBar(bool dark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  Icons.alt_route_rounded,
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
                        'Google Directions • Driving Mode',
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
    );
  }

  Widget _buildIncidentFocusCard() {
    return Container(
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
                      'CORRIDOR DETOUR ACTIVE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
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
                const SizedBox(height: 2),
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
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive search card that triggers Google Directions API & Supabase caching
  Widget _buildRouteSearchCard(bool dark) {
    return StitchGlassCard(
      isDarkMode: dark,
      borderRadius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Origin Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _originController,
                              focusNode: _originFocusNode,
                              onChanged: (v) => _fetchOriginSuggestions(v),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Enter Origin (e.g. Sola, Gota)',
                              ),
                              onSubmitted: (_) => _fetchRoute(),
                            ),
                          ),
                          if (_originController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _originController.clear();
                                  _showOriginDropdown = false;
                                });
                              },
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white60),
                            ),
                        ],
                      ),
                    ),

                    // Origin Autocomplete Dropdown
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

                    const SizedBox(height: 6),

                    // Destination Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 10, color: Color(0xFFF43F5E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _destController,
                              focusNode: _destFocusNode,
                              onChanged: (v) => _fetchDestSuggestions(v),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Enter Destination (e.g. Iskcon)',
                              ),
                              onSubmitted: (_) => _fetchRoute(),
                            ),
                          ),
                          if (_destController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _destController.clear();
                                  _showDestDropdown = false;
                                });
                              },
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white60),
                            ),
                        ],
                      ),
                    ),

                    // Destination Autocomplete Dropdown
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
                          if (_originController.text.isNotEmpty) {
                            _fetchRoute();
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Swap Button
              GestureDetector(
                onTap: _swapStops,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Search CTA Button
              GestureDetector(
                onTap: _isLoadingRoute ? null : _fetchRoute,
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3338BDF8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoadingRoute
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                              const SizedBox(height: 2),
                              Text(
                                'Find',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Route Corridor Status Indicator (No API key on screen)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _currentRoute?.isFromSupabaseCache == true
                        ? Icons.check_circle_rounded
                        : Icons.alt_route_rounded,
                    size: 12,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _currentRoute?.isFromSupabaseCache == true
                        ? 'Optimized Corridor (Cached)'
                        : 'Ahmedabad Transit Network',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
              if (_currentRoute != null)
                Text(
                  '${_currentRoute!.distanceText} • ${_currentRoute!.durationText}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Container(
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
                  color: _isRouteLegs ? const Color(0x4D38BDF8) : Colors.transparent,
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
    );
  }

  /// 1. Interactive Google Maps & Street Polyline Canvas (No dummy data)
  Widget _buildCorridorPolylineCard(bool dark) {
    final route = _currentRoute;

    return StitchGlassCard(
      isDarkMode: dark,
      borderRadius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header: Live GPS status & Map Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Street Polyline Vector',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scope Selector: Route | City | Metro
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x2238BDF8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3338BDF8), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniScopeOption('Route', 'corridor'),
                        _buildMiniScopeOption('City', 'city'),
                        _buildMiniScopeOption('Metro', 'metro'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _satelliteMode = !_satelliteMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _satelliteMode
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                            : const Color(0x3306B6D4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF06B6D4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _satelliteMode ? Icons.satellite_alt_rounded : Icons.layers_rounded,
                            size: 11,
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _satelliteMode ? 'Satellite' : 'Roadmap',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Live GPS interactive chip
                  GestureDetector(
                    onTap: _locateUser,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x2600E5FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x5500E5FF), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentGps != null ? 'GPS Live (${_currentGps!.accuracyLabel})' : 'Live GPS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E5FF),
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

          const SizedBox(height: 10),

          // Real Map Canvas with Google Static Map tile showing street-accurate driving polyline
          Container(
            height: 220,
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
                  // Google Static Maps tile layer with InteractiveViewer for free panning & pinch/scroll zoom
                  if (route != null &&
                      route.encodedPolyline.isNotEmpty &&
                      TransitMapConfig.hasGoogleMapsApiKey)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          double? centerLat;
                          double? centerLng;
                          int? zoomLevel;
                          if (_mapScope == 'city') {
                            centerLat = TransitMapConfig.ahmedabadCenterLat;
                            centerLng = TransitMapConfig.ahmedabadCenterLng;
                            zoomLevel = TransitMapConfig.cityScopeZoom;
                          } else if (_mapScope == 'metro') {
                            centerLat = TransitMapConfig.metroRegionCenterLat;
                            centerLng = TransitMapConfig.metroRegionCenterLng;
                            zoomLevel = TransitMapConfig.metroScopeZoom;
                          }

                          return InteractiveViewer(
                            transformationController: _corridorMapController,
                            minScale: 0.6,
                            maxScale: 5.0,
                            boundaryMargin: const EdgeInsets.all(300),
                            panEnabled: true,
                            scaleEnabled: true,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: Image.network(
                                TransitMapConfig.buildStaticMapUrl(
                                  encodedPolyline: route.encodedPolyline,
                                  originLat: route.originLat,
                                  originLng: route.originLng,
                                  destLat: route.destLat,
                                  destLng: route.destLng,
                                  userLat: _currentGps?.latitude,
                                  userLng: _currentGps?.longitude,
                                  centerLat: centerLat,
                                  centerLng: centerLng,
                                  zoomLevel: zoomLevel,
                                  width: 640,
                                  height: 480,
                                  isDarkMode: dark,
                                  isSatellite: _satelliteMode,
                                ),
                                fit: BoxFit.cover,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                errorBuilder: (ctx, err, stack) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.map_rounded, size: 30, color: Color(0xFF38BDF8)),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Corridor Map: ${route.origin} → ${route.destination}',
                                          style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 36,
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter origin and destination above to view map corridor',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Origin Node Label Badge
                  if (route != null)
                    Positioned(
                      top: 12,
                      left: 10,
                      child: _buildMapNodeLabel(
                        '1. ${route.origin}',
                        const Color(0xFF10B981),
                      ),
                    ),

                  // Destination Node Label Badge
                  if (route != null)
                    Positioned(
                      bottom: 30,
                      right: 10,
                      child: _buildMapNodeLabel(
                        '2. ${route.destination}',
                        const Color(0xFFF43F5E),
                      ),
                    ),

                  // Map Controls (Fullscreen, Zoom In, Zoom Out, Locate Me, Recenter)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        // Full Screen Map CTA
                        GestureDetector(
                          onTap: () => _openFullScreenMap(context, dark),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x4438BDF8), width: 1),
                            ),
                            child: const Icon(Icons.fullscreen_rounded, size: 18, color: Color(0xFF38BDF8)),
                          ),
                        ),
                        // Zoom In (+)
                        GestureDetector(
                          onTap: () => _zoomIn(_corridorMapController),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xB30F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Zoom Out (-)
                        GestureDetector(
                          onTap: () => _zoomOut(_corridorMapController),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xB30F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove, size: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Locate Me / GPS Button
                        GestureDetector(
                          onTap: _locateUser,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xB30F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentGps != null ? const Color(0xFF00E5FF) : Colors.transparent,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              size: 15,
                              color: _currentGps != null ? const Color(0xFF00E5FF) : Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Recenter
                        GestureDetector(
                          onTap: () => _resetZoom(_corridorMapController),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xB30F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.center_focus_strong_rounded, size: 14, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pan & Zoom Indicator
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xCC060E20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x22FFFFFF), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app_outlined, size: 10, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              'Pan freely • Pinch or +/- to zoom',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScopeOption(String label, String scopeValue) {
    final isSelected = _mapScope == scopeValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapScope = scopeValue;
        });
        _corridorMapController.value = Matrix4.identity();
        _exploreMapController.value = Matrix4.identity();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF060E20) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  /// 2. Real Route Summary Card (Dynamic Distance, Time, Fare from Google Directions)
  Widget _buildRouteSummaryCard(bool dark) {
    final route = _currentRoute;

    return StitchGlassCard(
      isDarkMode: dark,
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      route == null
                          ? 'Corridor Search Ready'
                          : (route.isFromSupabaseCache ? 'Optimized Corridor (Cached)' : 'Live Street Directions'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ),
              if (route != null)
                Text(
                  '₹${route.fareAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF56E5A9),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            route != null
                ? '${route.origin} → ${route.destination}'
                : (_originController.text.isNotEmpty && _destController.text.isNotEmpty
                    ? '${_originController.text} → ${_destController.text}'
                    : 'Search a Corridor in Ahmedabad'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 10),

          // Real metric counters (Zero dummy defaults)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('DURATION', route?.durationText ?? '--', Icons.schedule_rounded),
              _buildMetric('DISTANCE', route?.distanceText ?? '--', Icons.route_rounded),
              _buildMetric('UNIFIED FARE', route != null ? '₹${route.fareAmount.toStringAsFixed(2)}' : '--', Icons.currency_rupee_rounded),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Dynamic Route Legs & Street Navigation Steps
  Widget _buildRouteLegsBreakdownCard(bool dark) {
    final route = _currentRoute;
    final steps = route?.steps ?? [];

    return StitchGlassCard(
      isDarkMode: dark,
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text(
                    'Corridor Navigation Steps',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x3338BDF8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${steps.length} Steps Traced',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (steps.isNotEmpty)
            ...steps.take(5).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final colors = [
                const Color(0xFF38BDF8),
                const Color(0xFFFFB95F),
                const Color(0xFF3B82F6),
                const Color(0xFF56E5A9),
                const Color(0xFFEC4899),
              ];
              final color = colors[idx % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildLegCard(
                  badge: 'S${idx + 1}',
                  badgeColor: color,
                  title: step.plainInstruction,
                  routeTag: 'Step ${idx + 1}',
                  distance: step.distanceText,
                  duration: step.durationText,
                ),
              );
            })
          else
            _buildLegCard(
              badge: 'L1',
              badgeColor: const Color(0xFF38BDF8),
              title: 'Corridor Transit: ${route?.origin ?? "Origin"} ➔ ${route?.destination ?? "Destination"}',
              routeTag: 'BRTS / AMTS Direct',
              distance: route?.distanceText ?? '11.4 km',
              duration: route?.durationText ?? '26 mins',
            ),
        ],
      ),
    );
  }

  Widget _buildLegCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required String routeTag,
    required String distance,
    required String duration,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$distance • $duration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        routeTag,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTicketCta() {
    final fare = _currentRoute?.fareAmount;
    final fareLabel = fare != null
        ? 'Book Instant Ticket (₹${fare.toStringAsFixed(2)})'
        : 'Book Instant QR Ticket';

    return GestureDetector(
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
              fareLabel,
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
    );
  }

  Widget _buildExploreMapView(bool dark) {
    final route = _currentRoute;

    return Column(
      children: [
        // Interactive Full-View Map Canvas with InteractiveViewer for 2D pan & zoom
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: const Color(0xFF060E20),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x38FFFFFF), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                if (route != null &&
                    route.encodedPolyline.isNotEmpty &&
                    TransitMapConfig.hasGoogleMapsApiKey)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        double? centerLat;
                        double? centerLng;
                        int? zoomLevel;
                        if (_mapScope == 'city') {
                          centerLat = TransitMapConfig.ahmedabadCenterLat;
                          centerLng = TransitMapConfig.ahmedabadCenterLng;
                          zoomLevel = TransitMapConfig.cityScopeZoom;
                        } else if (_mapScope == 'metro') {
                          centerLat = TransitMapConfig.metroRegionCenterLat;
                          centerLng = TransitMapConfig.metroRegionCenterLng;
                          zoomLevel = TransitMapConfig.metroScopeZoom;
                        }

                        return InteractiveViewer(
                          transformationController: _exploreMapController,
                          minScale: 0.5,
                          maxScale: 6.0,
                          boundaryMargin: const EdgeInsets.all(400),
                          panEnabled: true,
                          scaleEnabled: true,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: Image.network(
                              TransitMapConfig.buildStaticMapUrl(
                                encodedPolyline: route.encodedPolyline,
                                originLat: route.originLat,
                                originLng: route.originLng,
                                destLat: route.destLat,
                                destLng: route.destLng,
                                userLat: _currentGps?.latitude,
                                userLng: _currentGps?.longitude,
                                centerLat: centerLat,
                                centerLng: centerLng,
                                zoomLevel: zoomLevel,
                                width: 640,
                                height: 640,
                                isDarkMode: dark,
                                isSatellite: _satelliteMode,
                              ),
                              fit: BoxFit.cover,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 44,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Search a route to preview corridor map',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Origin Node
                Positioned(
                  left: 14,
                  top: 14,
                  child: _buildMapNodeLabel(
                    route?.origin ?? 'Origin',
                    const Color(0xFF10B981),
                  ),
                ),

                // Destination Node
                Positioned(
                  right: 14,
                  bottom: 40,
                  child: _buildMapNodeLabel(
                    route?.destination ?? 'Destination',
                    const Color(0xFFF43F5E),
                  ),
                ),

                // Top Scope Switcher
                Positioned(
                  top: 14,
                  left: 140,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4438BDF8), width: 0.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniScopeOption('Route', 'corridor'),
                        _buildMiniScopeOption('City Grid', 'city'),
                        _buildMiniScopeOption('Metro Wide', 'metro'),
                      ],
                    ),
                  ),
                ),

                // Floating Action Controls (Fullscreen, Zoom In/Out, Locate Me, Recenter, Satellite)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      // Full Screen Button
                      GestureDetector(
                        onTap: () => _openFullScreenMap(context, dark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xEE0F172A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fullscreen_rounded, size: 16, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 4),
                              Text(
                                'Full Screen',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Zoom In (+)
                      GestureDetector(
                        onTap: () => _zoomIn(_exploreMapController),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                          ),
                          child: const Icon(Icons.add, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Zoom Out (-)
                      GestureDetector(
                        onTap: () => _zoomOut(_exploreMapController),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                          ),
                          child: const Icon(Icons.remove, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Locate Me / GPS Button
                      GestureDetector(
                        onTap: _locateUser,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentGps != null ? const Color(0xFF00E5FF) : const Color(0x26FFFFFF),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: _currentGps != null ? const Color(0xFF00E5FF) : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Recenter
                      GestureDetector(
                        onTap: () => _resetZoom(_exploreMapController),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                          ),
                          child: const Icon(Icons.center_focus_strong_rounded, size: 15, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Satellite toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _satelliteMode = !_satelliteMode;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _satelliteMode ? const Color(0xFF38BDF8) : const Color(0x26FFFFFF),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            _satelliteMode ? Icons.map_rounded : Icons.satellite_alt_rounded,
                            size: 16,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Left GPS telemetry chip
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: _locateUser,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xEE0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4400E5FF), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _currentGps != null
                                ? 'Live GPS: ${_currentGps!.formattedCoords}'
                                : 'Acquiring GPS Location...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // GPS Telemetry Strip
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xEE060E20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.touch_app_outlined, size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              'Pan freely in 2D • Pinch or +/- to zoom',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
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
                              'GTFS Driving Trace',
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
      ],
    );
  }

  Widget _buildMapNodeLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xB30F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
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
}

/// Full-Screen Interactive Transit Map Viewer
/// Allows commuters to freely pan, drag, pinch-to-zoom, and explore the entire Ahmedabad transit corridor
class _FullScreenMapViewer extends StatefulWidget {
  final TransitRouteResult? route;
  final bool dark;
  final bool initialSatelliteMode;
  final TransitGpsLocation? initialGps;
  final String? initialScope;

  const _FullScreenMapViewer({
    required this.route,
    required this.dark,
    required this.initialSatelliteMode,
    this.initialGps,
    this.initialScope,
  });

  @override
  State<_FullScreenMapViewer> createState() => _FullScreenMapViewerState();
}

class _FullScreenMapViewerState extends State<_FullScreenMapViewer> {
  late final TransformationController _controller;
  late bool _satellite;
  late String _scope; // 'corridor', 'city', 'metro'
  TransitGpsLocation? _currentGps;
  StreamSubscription<TransitGpsLocation>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _satellite = widget.initialSatelliteMode;
    _scope = widget.initialScope ?? 'corridor';
    _currentGps = widget.initialGps;

    _gpsSub = TransitGpsService.instance.streamLocation().listen((loc) {
      if (mounted) setState(() => _currentGps = loc);
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _controller.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _controller.value = matrix;
  }

  void _zoomOut() {
    final matrix = _controller.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _controller.value = matrix;
  }

  void _reset() {
    _controller.value = Matrix4.identity();
  }

  Future<void> _locateMe() async {
    final loc = await TransitGpsService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentGps = loc;
      _scope = 'corridor';
    });
    _controller.value = Matrix4.identity();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: Color(0xFF00E5FF), size: 16),
            const SizedBox(width: 8),
            Text(
              'Live GPS: ${loc.formattedCoords} (${loc.accuracyLabel})',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xEE0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildScopeOption(String label, String value, IconData icon) {
    final isSelected = _scope == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _scope = value;
        });
        _controller.value = Matrix4.identity();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF060E20) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF060E20) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    double? centerLat;
    double? centerLng;
    int? zoomLevel;
    if (_scope == 'city') {
      centerLat = TransitMapConfig.ahmedabadCenterLat;
      centerLng = TransitMapConfig.ahmedabadCenterLng;
      zoomLevel = TransitMapConfig.cityScopeZoom;
    } else if (_scope == 'metro') {
      centerLat = TransitMapConfig.metroRegionCenterLat;
      centerLng = TransitMapConfig.metroRegionCenterLng;
      zoomLevel = TransitMapConfig.metroScopeZoom;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      body: Stack(
        children: [
          // 1. Full Screen Edge-to-Edge Interactive Map Canvas
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: _controller,
                  minScale: 0.5,
                  maxScale: 6.0,
                  boundaryMargin: const EdgeInsets.all(500),
                  panEnabled: true,
                  scaleEnabled: true,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: route != null && route.encodedPolyline.isNotEmpty
                        ? Image.network(
                            TransitMapConfig.buildStaticMapUrl(
                              encodedPolyline: route.encodedPolyline,
                              originLat: route.originLat,
                              originLng: route.originLng,
                              destLat: route.destLat,
                              destLng: route.destLng,
                              userLat: _currentGps?.latitude,
                              userLng: _currentGps?.longitude,
                              centerLat: centerLat,
                              centerLng: centerLng,
                              zoomLevel: zoomLevel,
                              width: 640,
                              height: 640,
                              isDarkMode: widget.dark,
                              isSatellite: _satellite,
                            ),
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Text(
                                'Failed to load map tile',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'No route active',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 2. Floating Top Header with Back, Scope Switcher & Route Title
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x40FFFFFF), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Exit Full Screen',
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

                // Map Scope Switcher (Route | City Grid | Metro Wide)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xEE0F172A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x38FFFFFF), width: 1),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScopeOption('Route', 'corridor', Icons.alt_route_rounded),
                      _buildScopeOption('City Grid', 'city', Icons.location_city_rounded),
                      _buildScopeOption('Metro Wide', 'metro', Icons.hub_rounded),
                    ],
                  ),
                ),

                // Active Corridor Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xEE0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        '${route?.origin ?? "Origin"} ➔ ${route?.destination ?? "Destination"}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Right Control Panel (Zoom In/Out, Locate Me, Recenter, Satellite)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 70,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 8),
                // Locate Me / GPS Button
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on Live GPS',
                  onTap: _locateMe,
                  iconColor: _currentGps != null ? const Color(0xFF00E5FF) : Colors.white,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: 'Recenter',
                  onTap: _reset,
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: _satellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                  tooltip: _satellite ? 'Roadmap Mode' : 'Satellite Mode',
                  onTap: () => setState(() => _satellite = !_satellite),
                  iconColor: const Color(0xFF38BDF8),
                ),
              ],
            ),
          ),

          // 4. Floating Bottom Telemetry & Navigation Bar with Live GPS
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xEE0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMetricChip('DISTANCE', route?.distanceText ?? '--', Icons.straighten_rounded),
                      const SizedBox(width: 14),
                      _buildMetricChip('DURATION', route?.durationText ?? '--', Icons.timer_outlined),
                      const SizedBox(width: 14),
                      _buildMetricChip('FARE', '₹${(route?.fareAmount ?? 9.0).toStringAsFixed(2)}', Icons.confirmation_number_outlined),
                    ],
                  ),
                  // Live GPS Coordinates indicator
                  GestureDetector(
                    onTap: _locateMe,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0x2200E5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x5500E5FF), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4, spreadRadius: 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentGps != null
                                ? 'GPS: ${_currentGps!.formattedCoords} (${_currentGps!.accuracyLabel})'
                                : 'Acquiring GPS...',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E5FF),
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
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xEE0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x38FFFFFF), width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


