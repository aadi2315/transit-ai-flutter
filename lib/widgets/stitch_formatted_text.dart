import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A sleek, modern text renderer that formats AI transit responses,
/// converting markdown bold syntax (**text**), headers (###), and bullet points (* / •)
/// into clean, cool, and readable typography without weird raw asterisks.
class StitchFormattedText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Color? boldColor;
  final bool isUser;

  const StitchFormattedText({
    super.key,
    required this.text,
    required this.baseStyle,
    this.boldColor,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanText = _preprocessText(text);
    final spans = _buildTextSpans(cleanText);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  /// Clean up raw formatting artifacts, unmatched asterisks, and messy bullets
  String _preprocessText(String input) {
    var s = input;

    // Convert __bold__ to **bold**
    s = s.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => '**${m[1]}**');

    // Remove raw markdown bold headers like "* **Location:**" into "• Location:"
    s = s.replaceAll(RegExp(r'^\s*[*•-]\s*\*\*', multiLine: true), '• **');

    // Remove lone trailing unclosed bold tags (e.g. "**Impact" at the end of text)
    if (s.endsWith('**')) {
      s = s.substring(0, s.length - 2);
    }
    final asteriskCount = RegExp(r'\*\*').allMatches(s).length;
    if (asteriskCount % 2 != 0) {
      // Unclosed bold tag somewhere in text, remove the last orphan '**'
      final lastIdx = s.lastIndexOf('**');
      if (lastIdx != -1) {
        s = s.substring(0, lastIdx) + s.substring(lastIdx + 2);
      }
    }

    return s.trim();
  }

  /// Build styled TextSpans with bold emphasis, bullet points, and section tags
  List<InlineSpan> _buildTextSpans(String content) {
    final List<InlineSpan> spans = [];
    final lines = content.split('\n');

    final highlightColor = boldColor ??
        (isUser
            ? const Color(0xFF001E2B)
            : (baseStyle.color == Colors.white || baseStyle.color?.opacity == 1.0
                ? const Color(0xFF38BDF8)
                : const Color(0xFF0284C7)));

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];

      // Detect and format markdown headers (### Header -> Header)
      bool isMarkdownHeader = false;
      if (RegExp(r'^\s*#{1,6}\s+').hasMatch(line)) {
        isMarkdownHeader = true;
        line = line.replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '');
      }

      // Convert leading '*' or '-' bullet to a clean '•'
      if (RegExp(r'^\s*[*•-]\s+').hasMatch(line)) {
        line = line.replaceFirst(RegExp(r'^\s*[*•-]\s+'), '•  ');
      }

      // Check if line is a major section title (e.g. starting with an emoji like 🚨, ⚠️, 🧭, 💡, 📍)
      final isEmojiHeader = isMarkdownHeader ||
          RegExp(r'^(🚨|⚠️|🧭|💡|📍|📊|⚡|✅|🚌|🚇)\s+[A-Za-z0-9\s&/_-]+:?')
              .hasMatch(line.replaceAll('**', ''));

      // Parse inline bold chunks (**bold text**) inside the line
      final lineSpans = _parseInlineFormatting(
        line,
        highlightColor: highlightColor,
        isHeaderLine: isEmojiHeader,
      );

      spans.addAll(lineSpans);

      // Add line break between lines
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  /// Parse inline bold `**text**` and clean text
  List<InlineSpan> _parseInlineFormatting(
    String line, {
    required Color highlightColor,
    bool isHeaderLine = false,
  }) {
    final List<InlineSpan> inlineSpans = [];

    // Split by '**' delimiter
    final parts = line.split('**');

    for (int j = 0; j < parts.length; j++) {
      final part = parts[j];
      if (part.isEmpty) continue;

      final isBold = (j % 2 != 0); // Odd indices were inside **...**

      if (isBold || isHeaderLine) {
        inlineSpans.add(
          TextSpan(
            text: part,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: isUser ? const Color(0xFF002233) : highlightColor,
              letterSpacing: isHeaderLine ? 0.2 : 0.05,
            ),
          ),
        );
      } else {
        // Check for *italic* or single asterisk emphasis inside normal text
        if (part.contains('*') && RegExp(r'\*[^*\n]+\*').hasMatch(part)) {
          final subParts = part.split('*');
          for (int k = 0; k < subParts.length; k++) {
            final sub = subParts[k];
            if (sub.isEmpty) continue;
            final isItalic = (k % 2 != 0);
            inlineSpans.add(
              TextSpan(
                text: sub,
                style: baseStyle.copyWith(
                  fontWeight: isItalic ? FontWeight.w700 : FontWeight.w500,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            );
          }
        } else {
          inlineSpans.add(
            TextSpan(
              text: part.replaceAll('*', ''), // Clean any stray lone asterisks
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
      }
    }

    return inlineSpans;
  }
}
