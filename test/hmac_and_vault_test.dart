import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transit_app/core/crypto/hmac_signer.dart';
import 'package:transit_app/core/storage/local_transit_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HMAC-SHA256 Dynamic Token Signer Tests', () {
    test('Generates structured dynamic ticket payload with signature', () {
      final payload = HmacTokenSigner.generateDynamicTicketPayload(
        ticketId: 'TKT-TEST1234',
        origin: 'Sola Bhagwat',
        destination: 'Iskcon Cross Rd',
        fare: 9.0,
      );

      expect(payload.startsWith('TKT-AI|V1|TKT-TEST1234'), isTrue);
      final parts = payload.split('|');
      expect(parts.length, 8);
      expect(parts[2], 'TKT-TEST1234');
      expect(parts[3], 'Sola Bhagwat');
      expect(parts[4], 'Iskcon Cross Rd');
      expect(parts[5], '9.00');
      expect(parts[7].length, 16); // 16-char hex signature
    });

    test('Verifies valid dynamic token matching current time window', () {
      final now = DateTime.now();
      final payload = HmacTokenSigner.generateDynamicTicketPayload(
        ticketId: 'TKT-VALID5678',
        origin: 'Kalupur Metro',
        destination: 'Shivranjani',
        fare: 15.0,
        time: now,
      );

      final result = HmacTokenSigner.verifyDynamicPayload(
        payload,
        scanTime: now,
      );

      expect(result.isValid, isTrue);
      expect(result.status, ValidationStatus.valid);
      expect(result.ticketId, 'TKT-VALID5678');
      expect(result.origin, 'Kalupur Metro');
      expect(result.destination, 'Shivranjani');
      expect(result.fare, 15.0);
    });

    test('Rejects expired token older than rotation window', () {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 45));
      final payload = HmacTokenSigner.generateDynamicTicketPayload(
        ticketId: 'TKT-EXPIRED001',
        origin: 'Sola Bhagwat',
        destination: 'Iskcon Cross Rd',
        fare: 9.0,
        time: pastTime,
      );

      final result = HmacTokenSigner.verifyDynamicPayload(
        payload,
        scanTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.status, ValidationStatus.expiredWindow);
      expect(result.message.contains('Expired'), isTrue);
    });

    test('Rejects counterfeit token with tampered signature', () {
      const forgedPayload =
          'TKT-AI|V1|TKT-HACK999|Sola Bhagwat|Iskcon Cross Rd|9.00|1000|0000000000000000';

      final result = HmacTokenSigner.verifyDynamicPayload(
        forgedPayload,
        scanTime: DateTime.now(),
      );

      expect(result.isValid, isFalse);
      expect(result.status, ValidationStatus.tamperedSignature);
      expect(result.message.contains('Fraud Alert'), isTrue);
    });
  });

  group('LocalTransitVault Offline Tests', () {
    test('Saves and reads active ticket offline', () async {
      final vault = LocalTransitVault.instance;
      await vault.saveActiveTicket({
        'ticket_id': 'TKT-OFFLINE99',
        'origin': 'Vastrapur',
        'destination': 'Kalupur',
        'fare': 12.0,
      });

      final cached = await vault.getActiveTicket();
      expect(cached, isNotNull);
      expect(cached!['ticket_id'], 'TKT-OFFLINE99');
      expect(cached['origin'], 'Vastrapur');
      expect(cached['fare'], 12.0);
    });

    test('Verifies default Conductor Shift PIN', () async {
      final vault = LocalTransitVault.instance;
      expect(await vault.verifyConductorPin('1234'), isTrue);
      expect(await vault.verifyConductorPin('0000'), isFalse);
    });

    test('Prevents duplicate ticket scan in same shift', () async {
      final vault = LocalTransitVault.instance;
      await vault.resetShiftLogs();

      final firstScan = await vault.markTicketValidatedInShift('TKT-ONCE');
      expect(firstScan, isTrue);

      final secondScan = await vault.markTicketValidatedInShift('TKT-ONCE');
      expect(secondScan, isFalse);
    });
  });
}
