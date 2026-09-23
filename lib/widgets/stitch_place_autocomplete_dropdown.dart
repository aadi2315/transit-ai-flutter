import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transit_place_service.dart';

class StitchPlaceAutocompleteDropdown extends StatelessWidget {
  final List<TransitPlaceSuggestion> suggestions;
  final bool isDarkMode;
  final ValueChanged<TransitPlaceSuggestion> onSelect;

  const StitchPlaceAutocompleteDropdown({
    super.key,
    required this.suggestions,
    required this.isDarkMode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    const bg = Colors.white;
    const border = Color(0xFFA5F3FC);
    const primaryTextColor = Color(0xFF0F172A);
    const subTextColor = Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF0891B2)),
                  const SizedBox(width: 5),
                  Text(
                    'SUGGESTED TRANSIT STOPS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0891B2),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // Items
            ...suggestions.map((item) {
              return InkWell(
                onTap: () => onSelect(item),
                hoverColor: const Color(0x1A0891B2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.iconColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 15,
                          color: item.iconColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
