import 'package:flutter/material.dart';

class StitchProfileButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onTap;
  final double size;

  const StitchProfileButton({
    super.key,
    required this.isDarkMode,
    required this.onTap,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Account & Profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: isDarkMode
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  size: size * 0.50,
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
