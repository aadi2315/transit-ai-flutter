import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local offline storage vault for Transit AI tickets, passes, and conductor shift state.
/// Ensures 100% offline availability in underground corridors and cellular dead zones.
class LocalTransitVault {
  static final LocalTransitVault instance = LocalTransitVault._internal();
  LocalTransitVault._internal();

  static const String _keyActiveTicket = 'transit_ai_active_ticket_v2';
  static const String _keyActivePass = 'transit_ai_active_pass_v2';
  static const String _keyConductorPin = 'transit_ai_conductor_shift_pin';
  static const String _keyValidatedTickets = 'transit_ai_shift_validated_tickets';

  static const String _keyPastJourneys = 'transit_ai_past_journeys_v2';

  /// Save confirmed active ticket locally
  Future<void> saveActiveTicket(Map<String, dynamic> ticketData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveTicket, jsonEncode(ticketData));
      debugPrint('[LocalTransitVault] Active ticket saved to offline vault.');

      // Also record in journey history
      final origin = ticketData['origin'] ?? 'Origin';
      final dest = ticketData['destination'] ?? 'Destination';
      final fare = (ticketData['fare'] as num?)?.toDouble() ?? 9.0;
      final line = ticketData['line_info'] ?? 'BRTS Corridor';
      await recordJourney(origin: origin, destination: dest, fare: fare, lineInfo: line);
    } catch (e) {
      debugPrint('[LocalTransitVault] Error saving ticket: $e');
    }
  }

  /// Record a journey in local history
  Future<void> recordJourney({
    required String origin,
    required String destination,
    required double fare,
    required String lineInfo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPastJourneys) ?? [];
      final item = jsonEncode({
        'title': '$origin → $destination',
        'fare': '₹${fare.toStringAsFixed(2)}',
        'badgeText': lineInfo,
        'timeText': 'Recent',
      });
      list.insert(0, item);
      if (list.length > 10) list.removeLast();
      await prefs.setStringList(_keyPastJourneys, list);
    } catch (_) {}
  }

  /// Get past journeys from local history
  Future<List<Map<String, dynamic>>> getPastJourneys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPastJourneys) ?? [];
      final results = <Map<String, dynamic>>[];
      for (final raw in list) {
        try {
          results.add(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Get active ticket from offline storage
  Future<Map<String, dynamic>?> getActiveTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyActiveTicket);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[LocalTransitVault] Error reading ticket: $e');
    }
    return null;
  }

  /// Clear active ticket
  Future<void> clearActiveTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveTicket);
    } catch (_) {}
  }

  /// Save student concession pass locally
  Future<void> saveActivePass(Map<String, dynamic> passData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActivePass, jsonEncode(passData));
      debugPrint('[LocalTransitVault] Concession pass saved to offline vault.');
    } catch (e) {
      debugPrint('[LocalTransitVault] Error saving pass: $e');
    }
  }

  /// Get student concession pass from offline storage
  Future<Map<String, dynamic>?> getActivePass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyActivePass);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[LocalTransitVault] Error reading pass: $e');
    }
    return null;
  }

  /// Verify Conductor Shift PIN (default: '1234')
  Future<bool> verifyConductorPin(String enteredPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString(_keyConductorPin) ?? '1234';
      return storedPin == enteredPin.trim();
    } catch (_) {
      return enteredPin.trim() == '1234';
    }
  }

  /// Set custom Conductor Shift PIN
  Future<void> setConductorPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyConductorPin, pin.trim());
    } catch (_) {}
  }

  /// Record a ticket ID as used during current conductor shift (anti-duplicate check)
  Future<bool> markTicketValidatedInShift(String ticketId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyValidatedTickets) ?? [];
      if (list.contains(ticketId)) {
        return false; // Already validated!
      }
      list.add(ticketId);
      await prefs.setStringList(_keyValidatedTickets, list);
      return true; // Newly validated
    } catch (_) {
      return true;
    }
  }

  /// Clear shift validation cache
  Future<void> resetShiftLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyValidatedTickets);
    } catch (_) {}
  }
}
