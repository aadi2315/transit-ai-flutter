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
    final imagePath = isDarkMode
        ? 'assets/images/gift_city_night.jpg'
        : 'assets/images/gift_city_sunset.jpg';

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF070D1E) : const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. Crisp, High-Resolution GIFT City Aerial Wallpaper (Night for Dark, Sunset for Light)
          // Unblurred, full resolution coverage
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Image.asset(
                imagePath,
                key: ValueKey<String>(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                            ? const [Color(0xFF070D1E), Color(0xFF0B1326)]
                            : const [Color(0xFFE06516), Color(0xFF1E293B)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Translucent gradient scrim for contrast (preserves crystal clarity of wallpaper)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [
                            Colors.black.withValues(alpha: 0.28),
                            const Color(0xFF070D1E).withValues(alpha: 0.52),
                          ]
                        : [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Screen Content
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}
