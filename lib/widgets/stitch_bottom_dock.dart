import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchBottomDock extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final bool? isDarkMode;

  const StitchBottomDock({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    this.isDarkMode,
  });

  static const List<String> tabs = ['SEARCH', 'ROUTE', 'ASK', 'PASSES', 'WALLET'];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        constraints: const BoxConstraints(maxWidth: 396),
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: const Color(0xFFA5F3FC),
                  width: 1.2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  final beamLeft = activeIndex * tabWidth;

                  return Stack(
                    children: [
                      // Conical Spotlight Beam (Vibrant Transit Cyan)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        left: beamLeft,
                        top: 0,
                        width: tabWidth,
                        height: constraints.maxHeight,
                        child: CustomPaint(
                          painter: _ConicalSpotlightPainter(),
                        ),
                      ),

                      // Tabs row
                      Row(
                        children: List.generate(tabs.length, (index) {
                          final isSelected = activeIndex == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onTabSelected(index),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  tabs[index],
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.8,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    letterSpacing: 0.3,
                                    color: isSelected
                                        ? const Color(0xFF0891B2)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConicalSpotlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Spotlight Cone Path (Trapezoid expanding downwards)
    final path = Path();
    path.moveTo(size.width * 0.28, 0);
    path.lineTo(size.width * 0.72, 0);
    path.lineTo(size.width * 0.96, size.height);
    path.lineTo(size.width * 0.04, size.height);
    path.close();

    // Spotlight Gradient Fill (Cyan glow)
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFCFFAFE).withValues(alpha: 0.85),
          const Color(0xFFA5F3FC).withValues(alpha: 0.40),
          const Color(0xFF06B6D4).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Emitter Light Bar at the top
    final emitterWidth = size.width * 0.36;
    final emitterLeft = (size.width - emitterWidth) / 2;
    final emitterRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(emitterLeft, 0, emitterWidth, 3.5),
      const Radius.circular(3),
    );

    // Emitter Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF0891B2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(emitterRRect, glowPaint);

    // Emitter Core
    final corePaint = Paint()..color = const Color(0xFF0891B2);
    canvas.drawRRect(emitterRRect, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
