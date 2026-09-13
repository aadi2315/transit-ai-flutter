import 'dart:ui';
import 'package:flutter/material.dart';

class StitchGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blur;
  final VoidCallback? onTap;
  final bool hasCyanGlow;
  final bool? isDarkMode;

  const StitchGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.blur = 16.0,
    this.onTap,
    this.hasCyanGlow = false,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);

    final defaultBg = dark
        ? const Color(0xB30F172A)
        : const Color(0xEBFFFFFF);

    final defaultBorder = dark
        ? const Color(0x2EFFFFFF)
        : const Color(0x80FFFFFF);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (hasCyanGlow)
            BoxShadow(
              color: dark ? const Color(0x3338BDF8) : const Color(0x400284C7),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x25000000),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? defaultBorder,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
