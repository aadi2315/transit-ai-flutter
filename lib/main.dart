import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/stitch_theme.dart';
import 'screens/stitch_auth_screen.dart';
import 'screens/stitch_profile_screen.dart';
import 'screens/stitch_home_screen.dart';
import 'screens/stitch_route_screen.dart';
import 'screens/stitch_ask_route_screen.dart';
import 'screens/stitch_passes_screen.dart';
import 'screens/stitch_payment_qr_screen.dart';
import 'screens/pravha_splash_screen.dart';
import 'services/supabase_service.dart';
import 'services/google_directions_service.dart';
import 'services/transit_routing_service.dart';
import 'config/transit_map_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dynamic web Google Maps loader if key is present
  TransitMapConfig.initializeWebMaps();

  // Initialize Supabase Cloud Backend
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  runApp(const StitchTransitApp());
}

class StitchTransitApp extends StatefulWidget {
  final bool enableSplash;

  const StitchTransitApp({super.key, this.enableSplash = true});

  @override
  State<StitchTransitApp> createState() => _StitchTransitAppState();
}

class _StitchTransitAppState extends State<StitchTransitApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.enableSplash;
  }

  // 0: Search (Home), 1: Route, 2: Ask Route (Q&A), 3: Passes (Concessions), 4: Wallet (Fare & QR Ticket), 5: Auth (Sign In/Up), 6: Profile
  int _currentScreenIndex = 0;
  int _previousScreenIndex = 0;
  String? _focusedLocation;
  String? _focusedIncident;
  String? _searchedOrigin;
  String? _searchedDestination;
  TransitRouteResult? _activeRoute;
  TransitRoutingResult? _activeTransitResult;

  void _toggleTheme() {
    setState(() {
      _themeMode = ThemeMode.light;
    });
  }

  void _setScreen(int index) {
    setState(() {
      if (_currentScreenIndex != 5 && _currentScreenIndex != 6) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = index;
    });
  }

  void _bookTicket(TransitRouteResult? route, TransitRoutingResult? transitResult) {
    setState(() {
      _activeRoute = route;
      _activeTransitResult = transitResult;
      if (route != null) {
        _searchedOrigin = route.origin;
        _searchedDestination = route.destination;
      }
      if (_currentScreenIndex != 5 && _currentScreenIndex != 6) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = 4;
    });
  }

  void _onRouteUpdated(TransitRouteResult? route, TransitRoutingResult? transitResult) {
    setState(() {
      _activeRoute = route;
      _activeTransitResult = transitResult;
      if (route != null) {
        _searchedOrigin = route.origin;
        _searchedDestination = route.destination;
      }
    });
  }

  void _navigateToRouteWithSearch(String origin, String destination) {
    setState(() {
      _searchedOrigin = origin;
      _searchedDestination = destination;
      _activeRoute = null;
      _activeTransitResult = null;
      if (_currentScreenIndex != 5 && _currentScreenIndex != 6) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = 1;
    });
  }

  void _navigateToRouteWithFocus(String location, String? incident) {
    setState(() {
      _focusedLocation = location;
      _focusedIncident = incident;
      if (_currentScreenIndex != 5 && _currentScreenIndex != 6) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = 1;
    });
  }

  void _clearRouteFocus() {
    setState(() {
      _focusedLocation = null;
      _focusedIncident = null;
    });
  }

  void _openProfile() {
    setState(() {
      if (_currentScreenIndex != 5 && _currentScreenIndex != 6) {
        _previousScreenIndex = _currentScreenIndex;
      }
      if (SupabaseService.instance.isLoggedIn) {
        _currentScreenIndex = 6;
      } else {
        _currentScreenIndex = 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false;

    Widget currentScreen;
    switch (_currentScreenIndex) {
      case 0:
        currentScreen = StitchHomeScreen(
          onNavigateToRouteDetails: () => _setScreen(1),
          onSearchRoute: _navigateToRouteWithSearch,
          onNavigateToAskRoute: () => _setScreen(2),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          onReplaySplash: () => setState(() => _showSplash = true),
        );
        break;
      case 1:
        currentScreen = StitchRouteScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToAskRoute: () => _setScreen(2),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          focusLocation: _focusedLocation,
          focusIncident: _focusedIncident,
          onClearFocus: _clearRouteFocus,
          initialOrigin: _searchedOrigin,
          initialDestination: _searchedDestination,
          onRouteChanged: _onRouteUpdated,
          onBookTicket: _bookTicket,
        );
        break;
      case 2:
        // ASK ROUTE: Community Q&A, Live Reports, Gemini Assistant & Reactions
        currentScreen = StitchAskRouteScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToRouteDetails: () => _setScreen(1),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          onNavigateToRouteWithFocus: _navigateToRouteWithFocus,
        );
        break;
      case 3:
        // PASSES: Student & Commuter Passes & AI KYC Concessions
        currentScreen = StitchPassesScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToRouteDetails: () => _setScreen(1),
          onNavigateToAskRoute: () => _setScreen(2),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      case 4:
        // WALLET: Unified UPI Fare Checkout & Dynamic QR Ticket
        currentScreen = StitchPaymentQrScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToRouteDetails: () => _setScreen(1),
          onNavigateToAskRoute: () => _setScreen(2),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          activeRoute: _activeRoute,
          activeTransitResult: _activeTransitResult,
          searchedOrigin: _searchedOrigin,
          searchedDestination: _searchedDestination,
        );
        break;
      case 5:
        // AUTH / LOGIN: Screen accessed when not logged in or switching accounts
        currentScreen = StitchAuthScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: () => _setScreen(6),
          onToggleTheme: _toggleTheme,
          onBack: () => _setScreen(_previousScreenIndex),
          isDarkMode: isDark,
        );
        break;
      case 6:
        // COMMUTER PROFILE: Dedicated profile screen accessed when logged in
        currentScreen = StitchProfileScreen(
          onBack: () => _setScreen(_previousScreenIndex),
          onNavigateToHome: () => _setScreen(0),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToLogin: () => _setScreen(5),
          onLoggedOut: () {
            setState(() {
              _currentScreenIndex = 5;
            });
          },
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      default:
        currentScreen = StitchHomeScreen(
          onNavigateToRouteDetails: () => _setScreen(1),
          onSearchRoute: _navigateToRouteWithSearch,
          onNavigateToAskRoute: () => _setScreen(2),
          onNavigateToPasses: () => _setScreen(3),
          onNavigateToWallet: () => _setScreen(4),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          onReplaySplash: () => setState(() => _showSplash = true),
        );
        break;
    }

    return MaterialApp(
      title: 'PRAVHA',
      debugShowCheckedModeBanner: false,
      theme: StitchTheme.lightTheme,
      darkTheme: StitchTheme.darkTheme,
      themeMode: _themeMode,
      home: _showSplash
          ? PravhaSplashScreen(
              onFinish: () {
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                }
              },
            )
          : currentScreen,
    );
  }
}
