import 'package:flutter/material.dart';
import 'web_maps_bridge.dart';

/// Represents a transit station, stop, or landmark suggestion
class TransitPlaceSuggestion {
  final String name;
  final String subtitle;
  final String type; // 'brts', 'amts', 'metro', 'hub', 'place'
  final double latitude;
  final double longitude;

  const TransitPlaceSuggestion({
    required this.name,
    required this.subtitle,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  IconData get icon {
    switch (type) {
      case 'metro':
        return Icons.subway_rounded;
      case 'amts':
        return Icons.directions_bus_filled_rounded;
      case 'hub':
        return Icons.hub_rounded;
      case 'place':
        return Icons.location_on_rounded;
      case 'brts':
      default:
        return Icons.directions_bus_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'metro':
        return const Color(0xFF10B981);
      case 'amts':
        return const Color(0xFFF59E0B);
      case 'hub':
        return const Color(0xFFA855F7);
      case 'place':
        return const Color(0xFFF43F5E);
      case 'brts':
      default:
        return const Color(0xFF38BDF8);
    }
  }
}

/// Service providing offline Ahmedabad transit stops database and live Google Places autocomplete
class TransitPlaceService {
  TransitPlaceService._();
  static final TransitPlaceService instance = TransitPlaceService._();

  /// Curated Ahmedabad transit stops database
  static const List<TransitPlaceSuggestion> ahmedabadStops = [
    TransitPlaceSuggestion(
      name: 'Sola Bhagwat',
      subtitle: 'BRTS Hub • SG Highway Corridor',
      type: 'brts',
      latitude: 23.0827,
      longitude: 72.5284,
    ),
    TransitPlaceSuggestion(
      name: 'Gota Cross Road',
      subtitle: 'BRTS Station • SG Highway North',
      type: 'brts',
      latitude: 23.0970,
      longitude: 72.5350,
    ),
    TransitPlaceSuggestion(
      name: 'Iskcon Cross Road',
      subtitle: 'BRTS Major Concourse • SG Highway',
      type: 'brts',
      latitude: 23.0315,
      longitude: 72.5074,
    ),
    TransitPlaceSuggestion(
      name: 'Shivranjani',
      subtitle: 'BRTS Transfer Concourse • 132ft Ring Road',
      type: 'brts',
      latitude: 23.0234,
      longitude: 72.5312,
    ),
    TransitPlaceSuggestion(
      name: 'Kalupur Railway Station',
      subtitle: 'BRTS & Metro Multimodal Concourse',
      type: 'hub',
      latitude: 23.0298,
      longitude: 72.6010,
    ),
    TransitPlaceSuggestion(
      name: 'Ranip Cross Road',
      subtitle: 'BRTS Terminal • Central Bus Stand',
      type: 'brts',
      latitude: 23.0768,
      longitude: 72.5762,
    ),
    TransitPlaceSuggestion(
      name: 'RTO Circle',
      subtitle: 'BRTS Hub • Subhash Bridge Concourse',
      type: 'brts',
      latitude: 23.0620,
      longitude: 72.5790,
    ),
    TransitPlaceSuggestion(
      name: 'Nehrunagar',
      subtitle: 'BRTS Interchange • Ambawadi',
      type: 'brts',
      latitude: 23.0180,
      longitude: 72.5410,
    ),
    TransitPlaceSuggestion(
      name: 'Maninagar',
      subtitle: 'BRTS & Railway Junction • South Corridor',
      type: 'hub',
      latitude: 22.9978,
      longitude: 72.6025,
    ),
    TransitPlaceSuggestion(
      name: 'Paldi Cross Road',
      subtitle: 'BRTS Concourse • Ashram Road Hub',
      type: 'brts',
      latitude: 23.0125,
      longitude: 72.5620,
    ),
    TransitPlaceSuggestion(
      name: 'Vastrapur Lake',
      subtitle: 'AMTS / BRTS • IIM Ahmedabad Concourse',
      type: 'amts',
      latitude: 23.0372,
      longitude: 72.5298,
    ),
    TransitPlaceSuggestion(
      name: 'Science City',
      subtitle: 'BRTS Corridor • Sola North',
      type: 'brts',
      latitude: 23.0780,
      longitude: 72.5050,
    ),
    TransitPlaceSuggestion(
      name: 'GIFT City Tower',
      subtitle: 'GIFT City Multimodal Express Hub',
      type: 'hub',
      latitude: 23.1610,
      longitude: 72.6841,
    ),
    TransitPlaceSuggestion(
      name: 'GIFT City Club & Interchange',
      subtitle: 'GIFT City Business Corridor',
      type: 'brts',
      latitude: 23.1550,
      longitude: 72.6800,
    ),
    TransitPlaceSuggestion(
      name: 'Chandkheda',
      subtitle: 'BRTS Station • Zundal Circle',
      type: 'brts',
      latitude: 23.1090,
      longitude: 72.5850,
    ),
    TransitPlaceSuggestion(
      name: 'Bopal Approach',
      subtitle: 'BRTS Station • SP Ring Road',
      type: 'brts',
      latitude: 23.0340,
      longitude: 72.4720,
    ),
    TransitPlaceSuggestion(
      name: 'South Bopal',
      subtitle: 'AMTS & Feeder Corridor',
      type: 'amts',
      latitude: 23.0240,
      longitude: 72.4650,
    ),
    TransitPlaceSuggestion(
      name: 'Prahlad Nagar',
      subtitle: 'BRTS Station • Corporate Road',
      type: 'brts',
      latitude: 23.0120,
      longitude: 72.5080,
    ),
    TransitPlaceSuggestion(
      name: 'Helmet Cross Road',
      subtitle: 'BRTS Station • Drive-In Road',
      type: 'brts',
      latitude: 23.0450,
      longitude: 72.5340,
    ),
    TransitPlaceSuggestion(
      name: 'Geeta Mandir',
      subtitle: 'Central ST Bus Terminal • Astodia',
      type: 'hub',
      latitude: 23.0140,
      longitude: 72.5920,
    ),
    TransitPlaceSuggestion(
      name: 'Naroda Patiya',
      subtitle: 'BRTS East Terminal • Naroda Corridor',
      type: 'brts',
      latitude: 23.0680,
      longitude: 72.6450,
    ),
    TransitPlaceSuggestion(
      name: 'Odhav Ring Road',
      subtitle: 'BRTS East Hub • Industrial Corridor',
      type: 'brts',
      latitude: 23.0250,
      longitude: 72.6650,
    ),
    TransitPlaceSuggestion(
      name: 'CTM Cross Road',
      subtitle: 'BRTS Interchange • Express Highway',
      type: 'brts',
      latitude: 22.9910,
      longitude: 72.6280,
    ),
    TransitPlaceSuggestion(
      name: 'Vasna Terminus',
      subtitle: 'AMTS Central Terminal • APMC Market',
      type: 'amts',
      latitude: 22.9980,
      longitude: 72.5480,
    ),
    TransitPlaceSuggestion(
      name: 'Gujarat University',
      subtitle: 'Metro Line 1 & AMTS Station • Navrangpura',
      type: 'metro',
      latitude: 23.0360,
      longitude: 72.5450,
    ),
    TransitPlaceSuggestion(
      name: 'Law Garden',
      subtitle: 'AMTS Concourse • CG Road',
      type: 'amts',
      latitude: 23.0240,
      longitude: 72.5570,
    ),
    TransitPlaceSuggestion(
      name: 'Memnagar',
      subtitle: 'BRTS Station • Subhash Chowk',
      type: 'brts',
      latitude: 23.0510,
      longitude: 72.5350,
    ),
    TransitPlaceSuggestion(
      name: 'Vadaj Terminus',
      subtitle: 'AMTS & BRTS Interchange • Ashram Road',
      type: 'hub',
      latitude: 23.0550,
      longitude: 72.5730,
    ),
  ];

  /// Get suggestions matching query: local GTFS stations + live Google Places
  Future<List<TransitPlaceSuggestion>> getSuggestions(String query) async {
    final clean = query.trim().toLowerCase();

    // If query is empty or 1 character, return top hubs
    if (clean.isEmpty) {
      return ahmedabadStops.take(6).toList();
    }

    final List<TransitPlaceSuggestion> matches = [];
    final Set<String> seenNames = {};

    // 1. Match local curated transit stations first (instant response)
    for (final stop in ahmedabadStops) {
      final nameLow = stop.name.toLowerCase();
      final subLow = stop.subtitle.toLowerCase();
      if (nameLow.contains(clean) || subLow.contains(clean)) {
        matches.add(stop);
        seenNames.add(stop.name.toLowerCase());
      }
    }

    // 2. Query Google Places Autocomplete API via Web JS Bridge if on Web
    try {
      final jsPlaces = await queryJsPlaces(query);
      for (final p in jsPlaces) {
        final main = p['mainText'] ?? '';
        final sub = p['secondaryText'] ?? p['description'] ?? 'Ahmedabad, Gujarat';
        if (main.isNotEmpty && !seenNames.contains(main.toLowerCase())) {
          matches.add(
            TransitPlaceSuggestion(
              name: main,
              subtitle: sub,
              type: 'place',
              latitude: 23.0225,
              longitude: 72.5714,
            ),
          );
          seenNames.add(main.toLowerCase());
        }
      }
    } catch (e) {
      debugPrint('[TransitPlaceService] Live Places lookup note: $e');
    }

    return matches.take(7).toList();
  }
}
