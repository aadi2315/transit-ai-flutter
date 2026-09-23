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
      message: 'Sign In / Profile',
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
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA5F3FC),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: const Color(0xFF0891B2),
              size: size * 0.52,
            ),
          ),
        ),
      ),
    );
  }
}
