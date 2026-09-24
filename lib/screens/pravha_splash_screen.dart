import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Exact Pravha Splash Animation matching the HTML/CSS keyframe specification:
/// - 1.3s driveIn with cubic-bezier(0.34, 1.3, 0.64, 1) spring overshoot
/// - 0.9s shinePass with 30-deg rotated gloss shimmer pass starting at 1.2s
/// - Clean white (#FFFFFF) canvas matching the mobile device mockup
class PravhaSplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final bool autoDismiss;
  final Duration autoDismissDelay;

  const PravhaSplashScreen({
    super.key,
    this.onFinish,
    this.autoDismiss = true,
    this.autoDismissDelay = const Duration(milliseconds: 2700),
  });

  @override
  State<PravhaSplashScreen> createState() => _PravhaSplashScreenState();
}

class _PravhaSplashScreenState extends State<PravhaSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _driveInController;
  late Animation<double> _driveInCurved;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateYAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _shineController;
  late Animation<double> _shineCurved;

  Timer? _dismissTimer;
  Timer? _shineStartTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // 1. Drive-in animation: 1.3s cubic-bezier(0.34, 1.3, 0.64, 1)
    _driveInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _driveInCurved = CurvedAnimation(
      parent: _driveInController,
      curve: const Cubic(0.34, 1.3, 0.64, 1.0),
    );

    _scaleAnimation = Tween<double>(begin: 0.68, end: 1.0).animate(_driveInCurved);
    _translateYAnimation = Tween<double>(begin: 35.0, end: 0.0).animate(_driveInCurved);

    // Opacity fades in during first 65% of drive-in animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _driveInController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    // 2. Shine pass animation: 0.9s ease-out after 1.2s delay
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shineCurved = CurvedAnimation(
      parent: _shineController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    _driveInController.forward(from: 0.0);

    // Shine pass triggers after 1.2s delay
    _shineStartTimer?.cancel();
    _shineStartTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _shineController.forward(from: 0.0);
      }
    });

    // Auto dismiss after splash sequence finishes
    if (widget.autoDismiss && widget.onFinish != null) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(widget.autoDismissDelay, () {
        _dismiss();
      });
    }
  }

  void _dismiss() {
    if (_isExiting || !mounted) return;
    setState(() {
      _isExiting = true;
    });

    // Smooth subtle fade into main app
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onFinish?.call();
      }
    });
  }

  /// Replays the exact animation from scratch
  void restart() {
    _dismissTimer?.cancel();
    _shineStartTimer?.cancel();
    _driveInController.reset();
    _shineController.reset();
    setState(() {
      _isExiting = false;
    });
    _startAnimations();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _shineStartTimer?.cancel();
    _driveInController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double boxSize = 270.0;

    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedOpacity(
          opacity: _isExiting ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Stack(
            children: [
              // Center Logo with exact drive-in and gloss shimmer animations
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_driveInController, _shineController]),
                  builder: (context, child) {
                    final scale = _scaleAnimation.value;
                    final translateY = _translateYAnimation.value;
                    final opacity = _opacityAnimation.value.clamp(0.0, 1.0);

                    // Shine pass variables:
                    // left moves from -60% (-162px) to 140% (378px)
                    final t = _shineCurved.value;
                    final shineLeft = -0.6 * boxSize + t * (1.4 - (-0.6)) * boxSize;

                    // Opacity: 0% -> 0, 30% -> 1, 100% -> 0
                    double shineOpacity = 0.0;
                    if (_shineController.isAnimating || _shineController.isCompleted) {
                      if (t <= 0.3) {
                        shineOpacity = (t / 0.3).clamp(0.0, 1.0);
                      } else {
                        shineOpacity = ((1.0 - t) / 0.7).clamp(0.0, 1.0);
                      }
                    }

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, translateY),
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: boxSize,
                            height: boxSize,
                            child: ClipRect(
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  // Base Pravha AMTS Logo
                                  Center(
                                    child: Image.asset(
                                      'assets/images/pravha_logo.png',
                                      width: boxSize,
                                      height: boxSize,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to jpeg or placeholder if asset is resolving
                                        return Image.asset(
                                          'assets/images/pravha_logo.jpeg',
                                          width: boxSize,
                                          height: boxSize,
                                          fit: BoxFit.contain,
                                        );
                                      },
                                    ),
                                  ),

                                  // Gloss shimmer shine running across the exact image (rotate 30deg)
                                  if (shineOpacity > 0.005)
                                    Positioned(
                                      left: shineLeft,
                                      top: -0.5 * boxSize, // top: -50%
                                      width: 0.4 * boxSize, // width: 40%
                                      height: 2.0 * boxSize, // height: 200%
                                      child: Transform.rotate(
                                        angle: 30 * math.pi / 180,
                                        child: Opacity(
                                          opacity: shineOpacity,
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
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom subtle skip prompt
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap anywhere to enter',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
