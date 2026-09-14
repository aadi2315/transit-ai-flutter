import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/stitch_theme.dart';
import 'screens/stitch_auth_screen.dart';
import 'screens/stitch_home_screen.dart';
import 'screens/stitch_route_screen.dart';
import 'screens/stitch_passes_screen.dart';
import 'screens/stitch_payment_qr_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const StitchTransitApp());
}

class StitchTransitApp extends StatefulWidget {
  const StitchTransitApp({super.key});

  @override
  State<StitchTransitApp> createState() => _StitchTransitAppState();
}

class _StitchTransitAppState extends State<StitchTransitApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  // 0: Search (Home), 1: Route, 2: Passes (Stitch Concessions), 3: Wallet (Fare & QR Ticket), 4: Auth / Profile
  int _currentScreenIndex = 0;
  int _previousScreenIndex = 0;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _setScreen(int index) {
    setState(() {
      if (_currentScreenIndex != 4) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = index;
    });
  }

  void _openProfile() {
    setState(() {
      if (_currentScreenIndex != 4) {
        _previousScreenIndex = _currentScreenIndex;
      }
      _currentScreenIndex = 4;
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
          onNavigateToPasses: () => _setScreen(2),
          onNavigateToWallet: () => _setScreen(3),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      case 1:
        currentScreen = StitchRouteScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToPasses: () => _setScreen(2),
          onNavigateToWallet: () => _setScreen(3),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      case 2:
        // PASSES: Student & Commuter Passes & AI KYC Concessions (exact Stitch implementation)
        currentScreen = StitchPassesScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToRouteDetails: () => _setScreen(1),
          onNavigateToWallet: () => _setScreen(3),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      case 3:
        // WALLET: Unified UPI Fare Checkout & Dynamic QR Ticket
        currentScreen = StitchPaymentQrScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToRouteDetails: () => _setScreen(1),
          onNavigateToPasses: () => _setScreen(2),
          onNavigateToProfile: _openProfile,
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
        );
        break;
      case 4:
      default:
        // AUTH / PROFILE: Dedicated screen accessed only via the Profile button
        currentScreen = StitchAuthScreen(
          onNavigateToHome: () => _setScreen(0),
          onNavigateToWallet: () => _setScreen(3),
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
      home: currentScreen,
    );
  }
}
