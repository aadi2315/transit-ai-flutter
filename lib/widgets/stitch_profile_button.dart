import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

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
    final isLoggedIn = SupabaseService.instance.isLoggedIn;
    final fullName = SupabaseService.instance.currentUserProfile?['full_name'] as String?;
    final initials = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()[0].toUpperCase()
        : null;

    return Tooltip(
      message: 'Sign In / Profile',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isLoggedIn ? const Color(0xFFECFEFF) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLoggedIn
                        ? const Color(0xFF0891B2)
                        : const Color(0xFFA5F3FC),
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
                child: Center(
                  child: isLoggedIn && initials != null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0891B2),
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: const Color(0xFF0891B2),
                          size: size * 0.52,
                        ),
                ),
              ),
              if (isLoggedIn)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

