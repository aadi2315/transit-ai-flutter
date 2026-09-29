import 'app_env.dart';

class RazorpayConfig {
  // Test API credentials loaded dynamically from environment
  static String get keyId => AppEnv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_TbrlMReRXsMgY6',
      );
  static String get keySecret => AppEnv.get(
        'RAZORPAY_KEY_SECRET',
        fallback: 'UkBhByyF1s0eyXsbMXzMu8ES',
      );

  // Merchant details
  static const String merchantName = 'PRAVHA';
  static const String ticketBookingDescription = 'Bus Ticket Booking';
  static const String passBookingDescription = 'Student Concession Pass (80% Subsidy)';
  static const String currency = 'INR';
  static const String themeColor = '#1565C0';

  // Default prefill information
  static const String defaultContact = '9999999999';
  static const String defaultEmail = 'demo@pravha.com';
}
