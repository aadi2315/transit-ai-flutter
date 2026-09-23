import 'package:flutter/material.dart';

class StitchBackground extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;

  const StitchBackground({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Clean, minimalist warm light background with subtle top orange glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFECFEFF), // Subtle clean crystal cyan tint at top
                    Color(0xFFF8FAFC), // Pure clean light slate canvas
                    Color(0xFFFFFFFF), // Crisp bottom
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // 2. Screen Content
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}
