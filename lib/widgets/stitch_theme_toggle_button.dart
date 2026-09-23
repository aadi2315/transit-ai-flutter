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
      message: 'PRAVHA Light Mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleTheme,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA5F3FC),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140891B2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              color: const Color(0xFF0891B2),
              size: size * 0.48,
            ),
          ),
        ),
      ),
    );
  }
}
