import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic HMAC-SHA256 Dynamic Ticket Token Generator and Offline Verifier.
/// Aligned with Transit AI PRD v1.0 & Technical Architecture v1.0.
///
/// Ensures dynamic, screenshot-protected QR codes that rotate every 15 seconds
/// and can be verified 100% offline by conductor scanners.
class HmacTokenSigner {
  /// Default municipal transit authority shared verification secret key
  static const String defaultMunicipalSecret =
      'AMTS_BRTS_AHMEDABAD_MUNICIPAL_AUTH_KEY_2026';

  /// Default rotation window in seconds (15s per PRD & Architecture spec)
  static const int rotationWindowSeconds = 15;

  /// Calculate the current 15-second time window index
  static int getCurrentWindow({DateTime? time}) {
    final now = time ?? DateTime.now();
    final epochSeconds = now.millisecondsSinceEpoch ~/ 1000;
    return epochSeconds ~/ rotationWindowSeconds;
  }

  /// Calculates remaining seconds in the current 15-second window
  static int getRemainingWindowSeconds({DateTime? time}) {
    final now = time ?? DateTime.now();
    final epochSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final elapsed = epochSeconds % rotationWindowSeconds;
    return rotationWindowSeconds - elapsed;
  }

  /// Fractional progress (0.0 to 1.0) of current 15s window countdown
  static double getWindowProgress({DateTime? time}) {
    final remaining = getRemainingWindowSeconds(time: time);
    return remaining / rotationWindowSeconds;
  }

  /// Generate a dynamic signed HMAC-SHA256 payload for a ticket or pass
  ///
  /// Format:
  /// `TKT-AI|<version>|<ticketId>|<origin>|<dest>|<fare>|<windowIndex>|<signature>`
  static String generateDynamicTicketPayload({
    required String ticketId,
    required String origin,
    required String destination,
    required double fare,
    String? lineInfo,
    String? secretKey,
    DateTime? time,
  }) {
    final secret = secretKey ?? defaultMunicipalSecret;
    final window = getCurrentWindow(time: time);
    final cleanOrigin = origin.replaceAll('|', '-').trim();
    final cleanDest = destination.replaceAll('|', '-').trim();

    // Data string to sign
    final message =
        '$ticketId|$cleanOrigin|$cleanDest|${fare.toStringAsFixed(2)}|$window';
    final keyBytes = utf8.encode(secret);
    final messageBytes = utf8.encode(message);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    // Take first 16 hex chars for compact high-density QR scanning
    final signature = digest.toString().substring(0, 16).toUpperCase();

    return 'TKT-AI|V1|$ticketId|$cleanOrigin|$cleanDest|${fare.toStringAsFixed(2)}|$window|$signature';
  }

  /// Verification result structure for conductor handheld terminals
  static ConductorValidationResult verifyDynamicPayload(
    String rawPayload, {
    String? secretKey,
    DateTime? scanTime,
    int toleranceWindows = 1, // Allow +/- 1 window (15s) for device clock drift
  }) {
    final secret = secretKey ?? defaultMunicipalSecret;
    final parts = rawPayload.split('|');

    if (parts.length < 8 || parts[0] != 'TKT-AI') {
      return ConductorValidationResult(
        isValid: false,
        status: ValidationStatus.invalidFormat,
        message: 'Invalid PRAVHA Ticket Format',
      );
    }

    final ticketId = parts[2];
    final origin = parts[3];
    final destination = parts[4];
    final fareStr = parts[5];
    final windowStr = parts[6];
    final providedSig = parts[7];

    final int? scannedWindow = int.tryParse(windowStr);
    if (scannedWindow == null) {
      return ConductorValidationResult(
        isValid: false,
        status: ValidationStatus.invalidFormat,
        message: 'Corrupted Time Window Header',
      );
    }

    final currentWindow = getCurrentWindow(time: scanTime);
    final windowDifference = (currentWindow - scannedWindow).abs();

    // Check if window is within clock drift tolerance
    final isWindowFresh = windowDifference <= toleranceWindows;

    // Verify signature for the scanned window
    final message = '$ticketId|$origin|$destination|$fareStr|$scannedWindow';
    final keyBytes = utf8.encode(secret);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(message));
    final expectedSig = digest.toString().substring(0, 16).toUpperCase();

    if (providedSig != expectedSig) {
      return ConductorValidationResult(
        isValid: false,
        status: ValidationStatus.tamperedSignature,
        ticketId: ticketId,
        message: 'Cryptographic Signature Mismatch (Fraud Alert)',
      );
    }

    if (!isWindowFresh) {
      return ConductorValidationResult(
        isValid: false,
        status: ValidationStatus.expiredWindow,
        ticketId: ticketId,
        message: 'QR Code Expired. Commuter must refresh app screen.',
      );
    }

    return ConductorValidationResult(
      isValid: true,
      status: ValidationStatus.valid,
      ticketId: ticketId,
      origin: origin,
      destination: destination,
      fare: double.tryParse(fareStr) ?? 0.0,
      message: 'Valid Boarding Pass (Verified Offline)',
    );
  }
}

enum ValidationStatus {
  valid,
  expiredWindow,
  tamperedSignature,
  alreadyUsed,
  invalidFormat,
}

class ConductorValidationResult {
  final bool isValid;
  final ValidationStatus status;
  final String? ticketId;
  final String? origin;
  final String? destination;
  final double? fare;
  final String message;

  ConductorValidationResult({
    required this.isValid,
    required this.status,
    this.ticketId,
    this.origin,
    this.destination,
    this.fare,
    required this.message,
  });
}
