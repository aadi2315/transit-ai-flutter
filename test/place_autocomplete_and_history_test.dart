import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/config/transit_map_config.dart';
import 'package:transit_app/core/storage/local_transit_vault.dart';
import 'package:transit_app/services/transit_place_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transit Place Autocomplete Suggestions Tests', () {
    test('Returns transit stations for "Sola" query', () async {
      final results = await TransitPlaceService.instance.getSuggestions('Sola');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((s) => s.name.contains('Sola')), isTrue);
    });

    test('Returns transit stations for "Gota" query', () async {
      final results = await TransitPlaceService.instance.getSuggestions('Gota');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((s) => s.name.contains('Gota')), isTrue);
    });

    test('Returns transit stations for "Iskcon" query', () async {
      final results = await TransitPlaceService.instance.getSuggestions('Iskcon');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((s) => s.name.contains('Iskcon')), isTrue);
    });

    test('Returns top hubs for empty query', () async {
      final resultsEmpty = await TransitPlaceService.instance.getSuggestions('');
      expect(resultsEmpty.isNotEmpty, isTrue);
      expect(resultsEmpty.length <= 6, isTrue);
    });
  });

  group('LocalTransitVault Real Past Journeys Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and retrieves recorded journeys dynamically (no dummy data)', () async {
      final initialJourneys = await LocalTransitVault.instance.getPastJourneys();
      expect(initialJourneys.isEmpty, isTrue);

      await LocalTransitVault.instance.recordJourney(
        origin: 'Sola Bhagwat',
        destination: 'Iskcon Cross Road',
        fare: 9.0,
        lineInfo: 'BRTS Line 9U',
      );

      final updatedJourneys = await LocalTransitVault.instance.getPastJourneys();
      expect(updatedJourneys.length, equals(1));
      expect(updatedJourneys.first['title'], equals('Sola Bhagwat → Iskcon Cross Road'));
      expect(updatedJourneys.first['fare'], equals('₹9.00'));
      expect(updatedJourneys.first['badgeText'], equals('BRTS Line 9U'));
    });
  });

  group('Google Maps Configuration Tests', () {
    test('Google Maps API key is configured and valid', () {
      expect(TransitMapConfig.hasGoogleMapsApiKey, isTrue);
      expect(TransitMapConfig.googleMapsApiKey.startsWith('AIzaSy'), isTrue);
    });
  });
}
