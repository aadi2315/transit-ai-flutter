import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Pravha Splash Screen featuring entrance scale/translate
/// and a high-sheen 30-degree metallic sweep across the logo.
class PravhaSplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final Widget? nextScreen;

  const PravhaSplashScreen({
    super.key,
    this.onFinish,
    this.nextScreen,
  });

  @override
  State<PravhaSplashScreen> createState() => _PravhaSplashScreenState();
}

class _PravhaSplashScreenState extends State<PravhaSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _shineController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateYAnimation;

  late Animation<double> _shinePositionAnimation;
  late Animation<double> _shineOpacityAnimation;

  Timer? _shineTimer;
  Timer? _navigationTimer;

  static const double _boxSize = 270.0;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation: 1.3s duration with a 0.2s delay = 1500ms total
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // CSS: cubic-bezier(0.34, 1.3, 0.64, 1) running from 200ms to 1500ms
    final entranceCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.133, 1.0, curve: Cubic(0.34, 1.3, 0.64, 1.0)),
    );

    // CSS: scale(0.68) -> scale(1.0)
    _scaleAnimation = Tween<double>(begin: 0.68, end: 1.0).animate(entranceCurve);

    // CSS: opacity 0 -> 1 by 65% of the entrance duration
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.133, 0.65, curve: Curves.linear),
      ),
    );

    // CSS: translateY(35px) -> translateY(0px)
    _translateYAnimation = Tween<double>(begin: 35.0, end: 0.0).animate(entranceCurve);

    // 2. Shine sweep: 900ms duration, starts at 1200ms
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // CSS: left -60% to 140%
    _shinePositionAnimation = Tween<double>(
      begin: -0.60 * _boxSize,
      end: 1.40 * _boxSize,
    ).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeOut),
    );

    // CSS: opacity 0% -> 100% (at 30%) -> 0% (at 100%)
    _shineOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 70,
      ),
    ]).animate(_shineController);

    // Sequence execution
    _entranceController.forward();

    _shineTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _shineController.forward();
      }
    });

    // Navigate or trigger onFinish after full animation completes
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        if (widget.onFinish != null) {
          widget.onFinish!();
        } else if (widget.nextScreen != null) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => widget.nextScreen!,
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _shineTimer?.cancel();
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _translateYAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            width: _boxSize,
            height: _boxSize,
            clipBehavior: Clip.hardEdge, // Replicates CSS overflow: hidden
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // The Exact Logo Image Asset
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/pravha_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackLogo();
                    },
                  ),
                ),

                // CSS ::after equivalent (30-degree rotated linear gradient band)
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    return Positioned(
                      left: _shinePositionAnimation.value,
                      top: -0.5 * _boxSize,
                      width: 0.40 * _boxSize,
                      height: 2.0 * _boxSize,
                      child: Opacity(
                        opacity: _shineOpacityAnimation.value,
                        child: Transform.rotate(
                          angle: 30 * (math.pi / 180), // 30 degrees in radians
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0x00FFFFFF), // rgba(255, 255, 255, 0)
                                  Color(0x99FFFFFF), // rgba(255, 255, 255, 0.6)
                                  Color(0x00FFFFFF), // rgba(255, 255, 255, 0)
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Elegant fallback rendering in case image asset is momentarily unbundled
  Widget _buildFallbackLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF38BDF8), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330284C7),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 54,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PRAVHA',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AMTS TRANSIT AI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }
}

/// Fallback Standalone Dashboard (if PravhaSplashScreen is run independently)
class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: Text(
          'AMTS Transit Services Active',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
