import 'package:flutter/material.dart';

class StitchThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final double size;

  const StitchThemeToggleButton({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDarkMode ? 'Switch to Light Mode (Sunset)' : 'Switch to Dark Mode (Night)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleTheme,
          borderRadius: BorderRadius.circular(size / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xB30F172A)
                  : const Color(0xE6FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode
                    ? const Color(0x38FFFFFF)
                    : const Color(0x66FFFFFF),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? const Color(0x40FBBF24)
                      : const Color(0x25000000),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  ),
                );
              },
              child: Icon(
                isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey<bool>(isDarkMode),
                color: isDarkMode
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF0284C7),
                size: size * 0.46,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
