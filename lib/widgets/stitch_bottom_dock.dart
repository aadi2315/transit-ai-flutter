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

  static const List<String> tabs = ['SEARCH', 'ROUTE', 'PASSES', 'WALLET'];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        constraints: const BoxConstraints(maxWidth: 390),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? const Color(0x99000000)
                  : const Color(0x40000000),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xE0060E20) : const Color(0xF20F172A),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: dark ? const Color(0x38FFFFFF) : const Color(0x55FFFFFF),
                  width: 1.2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  final beamLeft = activeIndex * tabWidth;

                  return Stack(
                    children: [
                      // Conical Spotlight Beam
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
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
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                    shadows: isSelected
                                        ? const [
                                            Shadow(
                                              color: Color(0xFF38BDF8),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
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
    path.moveTo(size.width * 0.32, 0);
    path.lineTo(size.width * 0.68, 0);
    path.lineTo(size.width * 0.98, size.height);
    path.lineTo(size.width * 0.02, size.height);
    path.close();

    // Spotlight Gradient Fill
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFF22D3EE).withValues(alpha: 0.45),
          const Color(0xFF06B6D4).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    // Emitter Light Bar at the top
    final emitterWidth = size.width * 0.34;
    final emitterLeft = (size.width - emitterWidth) / 2;
    final emitterRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(emitterLeft, 0, emitterWidth, 3.5),
      const Radius.circular(3),
    );

    // Emitter Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(emitterRRect, glowPaint);

    // Emitter Core
    final corePaint = Paint()..color = Colors.white;
    canvas.drawRRect(emitterRRect, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
