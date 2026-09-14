import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/stitch_theme.dart';
import 'screens/stitch_auth_screen.dart';
import 'screens/stitch_home_screen.dart';
import 'screens/stitch_route_screen.dart';
import 'screens/stitch_ask_route_screen.dart';
import 'screens/stitch_passes_screen.dart';
import 'screens/stitch_payment_qr_screen.dart';
import 'screens/pravha_splash_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

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
  ThemeMode _themeMode = ThemeMode.dark;
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.enableSplash;
  }

  // 0: Search (Home), 1: Route, 2: Ask Route (Q&A), 3: Passes (Concessions), 4: Wallet (Fare & QR Ticket), 5: Auth / Profile
  int _currentScreenIndex = 0;
  int _previousScreenIndex = 0;
  String? _focusedLocation;
  String? _focusedIncident;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _setScreen(int index) {
    setState(() {
      if (_currentScreenIndex != 5) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = index;
    });
  }

  void _navigateToRouteWithFocus(String location, String? incident) {
    setState(() {
      _focusedLocation = location;
      _focusedIncident = incident;
      if (_currentScreenIndex != 5) {
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
      if (_currentScreenIndex != 5) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;

    Widget currentScreen;
    switch (_currentScreenIndex) {
      case 0:
        currentScreen = StitchHomeScreen(
          onNavigateToRouteDetails: () => _setScreen(1),
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
        );
        break;
      case 5:
      default:
        // AUTH / PROFILE: Dedicated screen accessed via the Profile button
        currentScreen = StitchAuthScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToWallet: () => _setScreen(4),
          onToggleTheme: _toggleTheme,
          onBack: () => _setScreen(_previousScreenIndex),
          isDarkMode: isDark,
        );
        break;
    }

    return MaterialApp(
      title: 'Transit AI',
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
