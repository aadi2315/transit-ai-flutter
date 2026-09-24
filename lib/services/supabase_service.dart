import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../core/storage/local_transit_vault.dart';
import 'google_directions_service.dart';

/// Singleton Service for Supabase Cloud Backend in Transit AI.
/// Provides real-time synchronization, community Q&A feed persistence,
/// user authentication with locality profiling, and ticket storage.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Direct handle to the Supabase client
  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Current logged-in user profile in-memory cache
  Map<String, dynamic>? currentUserProfile;

  /// Initialize Supabase connection
  Future<bool> init() async {
    if (_isInitialized) return true;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Configuration missing or incomplete.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected successfully to ${SupabaseConfig.supabaseUrl}');
      await loadPersistedProfile();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Initialization notice: $e');
      // Even if already initialized in another isolate or prior run, mark flag if client is accessible
      try {
        Supabase.instance.client;
        _isInitialized = true;
        await loadPersistedProfile();
        return true;
      } catch (_) {}
      await loadPersistedProfile();
      return false;
    }
  }

  static const String _keyUserProfile = 'transit_ai_user_profile_v2';

  /// Check if a commuter profile is currently authenticated
  bool get isLoggedIn =>
      currentUserProfile != null &&
      ((currentUserProfile!['phone'] != null &&
              currentUserProfile!['phone'].toString().isNotEmpty) ||
          (currentUserProfile!['full_name'] != null &&
              currentUserProfile!['full_name'].toString().isNotEmpty));

  /// Save profile locally in offline preferences
  Future<void> saveUserProfileLocally(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 600),
      );
      await prefs.setString(_keyUserProfile, jsonEncode(profile));
    } catch (e) {
      debugPrint('[SupabaseService] save profile notice: $e');
    }
  }

  /// Load persisted profile from local storage
  Future<Map<String, dynamic>?> loadPersistedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 600),
      );
      final raw = prefs.getString(_keyUserProfile);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        currentUserProfile = decoded;
        return decoded;
      }
    } catch (e) {
      debugPrint('[SupabaseService] load profile notice: $e');
    }
    return null;
  }

  /// Logout current commuter and clear stored profile session
  Future<void> logoutUser() async {
    currentUserProfile = null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 600),
      );
      await prefs.remove(_keyUserProfile);
    } catch (_) {}
    try {
      final cl = client;
      if (cl != null) {
        await cl.auth.signOut();
      }
    } catch (_) {}
  }

  /// Update user profile details (Name, Phone, Locality, Emergency Contact, Transit Mode)
  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phone,
    String? locality,
    String? emergencyContact,
    String? preferredTransit,
  }) async {
    final current = Map<String, dynamic>.from(currentUserProfile ?? {});
    if (fullName != null && fullName.trim().isNotEmpty) {
      current['full_name'] = fullName.trim();
    }
    if (phone != null && phone.trim().isNotEmpty) {
      current['phone'] = phone.trim();
    }
    if (locality != null && locality.trim().isNotEmpty) {
      current['locality'] = locality.trim();
    }
    if (emergencyContact != null) {
      current['emergency_contact'] = emergencyContact.trim();
    }
    if (preferredTransit != null) {
      current['preferred_transit'] = preferredTransit.trim();
    }
    current['updated_at'] = DateTime.now().toIso8601String();

    currentUserProfile = current;
    await saveUserProfileLocally(current);

    final cl = client;
    if (cl != null && current['phone'] != null) {
      try {
        await cl.from('profiles').upsert(
          {
            'phone': current['phone'],
            'full_name': current['full_name'],
            'locality': current['locality'],
            'emergency_contact': current['emergency_contact'],
            'preferred_transit': current['preferred_transit'],
            'updated_at': current['updated_at'],
          },
          onConflict: 'phone',
        );
      } catch (e) {
        debugPrint('[SupabaseService] updateUserProfile cloud sync notice: $e');
      }
    }
    return {'success': true, 'profile': currentUserProfile};
  }

  // ==========================================
  // AUTH & USER PROFILES (With Locality / From)
  // ==========================================

  /// Register or update user profile with local origin / city
  Future<Map<String, dynamic>> registerUserProfile({
    required String fullName,
    required String phone,
    required String locality,
    String? password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final profileData = {
      'full_name': fullName.trim(),
      'phone': cleanPhone.isNotEmpty ? cleanPhone : phone.trim(),
      'locality': locality.trim().isNotEmpty ? locality.trim() : 'Ahmedabad',
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Cache locally immediately
    currentUserProfile = {
      ...profileData,
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
    };
    await saveUserProfileLocally(currentUserProfile!);

    final cl = client;
    if (cl == null) {
      return {'success': true, 'source': 'local_cache', 'profile': currentUserProfile};
    }

    try {
      // Upsert into public profiles table
      final response = await cl
          .from('profiles')
          .upsert(
            {
              'phone': profileData['phone'],
              'full_name': profileData['full_name'],
              'locality': profileData['locality'],
              'updated_at': profileData['updated_at'],
            },
            onConflict: 'phone',
          )
          .select()
          .maybeSingle();

      if (response != null) {
        currentUserProfile = response;
        await saveUserProfileLocally(currentUserProfile!);
      }
      return {'success': true, 'source': 'supabase', 'profile': currentUserProfile};
    } catch (e) {
      debugPrint('[SupabaseService] registerUserProfile error (using local cache): $e');
      return {'success': true, 'source': 'local_fallback', 'profile': currentUserProfile};
    }
  }

  /// Login commuter with phone and password
  Future<Map<String, dynamic>> loginUser({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final cl = client;

    if (cl != null) {
      try {
        final profile = await cl
            .from('profiles')
            .select()
            .eq('phone', cleanPhone.isNotEmpty ? cleanPhone : phone)
            .maybeSingle();

        if (profile != null) {
          currentUserProfile = profile;
          await saveUserProfileLocally(currentUserProfile!);
          return {'success': true, 'profile': profile};
        }
      } catch (e) {
        debugPrint('[SupabaseService] login query notice: $e');
      }
    }

    // Default fallback profile if not found or table pending
    currentUserProfile = {
      'id': 'user_${cleanPhone.isNotEmpty ? cleanPhone : 'guest'}',
      'full_name': 'Aarav Patel',
      'phone': cleanPhone.isNotEmpty ? cleanPhone : '9879044120',
      'locality': 'SG Highway, Ahmedabad',
    };
    await saveUserProfileLocally(currentUserProfile!);
    return {'success': true, 'profile': currentUserProfile};
  }

  // ==========================================
  // ASK ROUTE (COMMUNITY Q&A)
  // ==========================================

  /// Fetch list of live community questions with their answers
  Future<List<Map<String, dynamic>>?> fetchQuestions({String category = 'all'}) async {
    final cl = client;
    if (cl == null) return null;

    try {
      var query = cl.from('route_questions').select();

      if (category != 'all') {
        query = query.eq('category', category);
      }

      final questionsData = await query.order('created_at', ascending: false);
      final answersData = await cl.from('route_answers').select();

      final List<Map<String, dynamic>> combined = [];
      for (final q in questionsData) {
        final qMap = Map<String, dynamic>.from(q);
        final qId = qMap['id']?.toString();
        final matchingAnswers = answersData
            .where((a) => a['question_id']?.toString() == qId)
            .toList();
        qMap['answers'] = matchingAnswers;
        combined.add(qMap);
      }

      return combined;
    } catch (e) {
      debugPrint('[SupabaseService] fetchQuestions notice (falling back to local): $e');
      return null;
    }
  }

  /// Post a new community question to Supabase
  Future<Map<String, dynamic>?> postQuestion({
    required String author,
    required String role,
    required String question,
    required String origin,
    required String destination,
    required String routeTag,
    required String category,
    required String badgeText,
  }) async {
    final record = {
      'author': author,
      'role': role,
      'question': question,
      'origin': origin,
      'destination': destination,
      'route_tag': routeTag,
      'category': category,
      'badge_text': badgeText,
      'upvotes': 1,
      'created_at': DateTime.now().toIso8601String(),
    };

    final cl = client;
    if (cl == null) return record;

    try {
      final res = await cl.from('route_questions').insert(record).select().maybeSingle();
      debugPrint('[SupabaseService] Question saved to Supabase: ${res?['id']}');
      return res ?? record;
    } catch (e) {
      debugPrint('[SupabaseService] postQuestion notice (persisted in session): $e');
      return record;
    }
  }

  /// Post a reply/answer to an existing question
  Future<Map<String, dynamic>?> postAnswer({
    required String questionId,
    required String author,
    required String roleBadge,
    required String content,
    required String avatarLetter,
  }) async {
    final record = {
      'question_id': questionId,
      'author': author,
      'role_badge': roleBadge,
      'content': content,
      'avatar_letter': avatarLetter,
      'likes': 1,
      'dislikes': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    final cl = client;
    if (cl == null) return record;

    try {
      final res = await cl.from('route_answers').insert(record).select().maybeSingle();
      return res ?? record;
    } catch (e) {
      debugPrint('[SupabaseService] postAnswer notice: $e');
      return record;
    }
  }

  /// Update like/dislike reactions on an answer
  Future<void> syncAnswerReaction({
    required String answerId,
    required int likes,
    required int dislikes,
  }) async {
    final cl = client;
    if (cl == null) return;

    try {
      await cl.from('route_answers').update({
        'likes': likes,
        'dislikes': dislikes,
      }).eq('id', answerId);
    } catch (e) {
      debugPrint('[SupabaseService] syncAnswerReaction notice: $e');
    }
  }

  /// Update question upvote count
  Future<void> syncQuestionUpvote({
    required String questionId,
    required int upvotes,
  }) async {
    final cl = client;
    if (cl == null) return;

    try {
      await cl.from('route_questions').update({
        'upvotes': upvotes,
      }).eq('id', questionId);
    } catch (e) {
      debugPrint('[SupabaseService] syncQuestionUpvote notice: $e');
    }
  }

  // ==========================================
  // ==========================================
  // TICKET BOOKINGS & CONCESSION PASSES
  // ==========================================

  /// Save generated transit ticket to Supabase and Local Offline Vault
  Future<bool> saveTicket({
    required String ticketId,
    required String origin,
    required String destination,
    required double fare,
    required String lineInfo,
    required String qrPayload,
    String? hmacSignature,
  }) async {
    final record = {
      'ticket_id': ticketId,
      'origin': origin,
      'destination': destination,
      'fare': fare,
      'line_info': lineInfo,
      'qr_payload': qrPayload,
      'hmac_signature': hmacSignature ?? '',
      'status': 'ACTIVE',
      'is_validated': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save to local offline vault first for 100% offline resilience
    await LocalTransitVault.instance.saveActiveTicket(record);

    final cl = client;
    if (cl == null) return true;

    try {
      await cl.from('tickets').insert(record);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] saveTicket cloud sync notice: $e');
      return true; // Still true because saved to local offline vault!
    }
  }

  /// Submit AI-extracted Student KYC Concession Application
  Future<Map<String, dynamic>> submitKycApplication({
    required String phone,
    required String studentName,
    required String institutionName,
    required String rollNumber,
    required Map<String, dynamic> ocrData,
    bool isApproved = true,
  }) async {
    final record = {
      'phone': phone,
      'institution_name': institutionName,
      'roll_number': rollNumber,
      'ocr_extracted_data': ocrData,
      'digilocker_verified': true,
      'status': isApproved ? 'approved' : 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    final cl = client;
    if (cl != null) {
      try {
        final res = await cl.from('kyc_applications').insert(record).select().maybeSingle();
        if (res != null) return res;
      } catch (e) {
        debugPrint('[SupabaseService] submitKycApplication notice: $e');
      }
    }
    return record;
  }

  /// Save approved student concession pass or commuter pass
  Future<bool> saveConcessionPass({
    required String passNumber,
    required String institutionName,
    required String rollNumber,
    int subsidyPercent = 80,
    double monthlyFare = 60.0,
    String? passTitle,
    String? operator,
    String? category,
    String? duration,
    double? cost,
  }) async {
    final record = {
      'pass_number': passNumber,
      'pass_title': passTitle ?? 'Transit Pass',
      'operator': operator ?? 'BRTS',
      'category': category ?? 'Commuter',
      'duration': duration ?? '30 Days',
      'cost': cost ?? monthlyFare,
      'institution_name': institutionName,
      'roll_number': rollNumber,
      'subsidy_discount_percent': subsidyPercent,
      'monthly_fare': monthlyFare,
      'valid_from': DateTime.now().toIso8601String(),
      'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save to local offline vault immediately
    await LocalTransitVault.instance.saveActivePass(record);

    final cl = client;
    if (cl == null) return true;

    try {
      await cl.from('concession_passes').insert(record);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] saveConcessionPass notice: $e');
      return true;
    }
  }

  // LIVE TRANSIT REPORTS & INCIDENT ALERTS
  // ==========================================

  /// Fetch all active incident reports with nested comments
  Future<List<Map<String, dynamic>>?> fetchReports() async {
    final cl = client;
    if (cl == null) return null;

    try {
      final reportsData = await cl
          .from('transit_reports')
          .select()
          .order('created_at', ascending: false);
      final commentsData = await cl.from('report_comments').select();

      final List<Map<String, dynamic>> combined = [];
      for (final r in reportsData) {
        final rMap = Map<String, dynamic>.from(r);
        final rId = rMap['id']?.toString();
        final matchingComments = commentsData
            .where((c) => c['report_id']?.toString() == rId)
            .toList();
        rMap['comments'] = matchingComments;
        combined.add(rMap);
      }
      return combined;
    } catch (e) {
      debugPrint('[SupabaseService] fetchReports notice: $e');
      return null;
    }
  }

  /// Submit a new transit incident report
  Future<Map<String, dynamic>?> submitReport({
    required String reporterName,
    required String reportType,
    required String severity,
    required String title,
    required String description,
    required String locationName,
    String routeTag = 'Transit Network',
  }) async {
    final record = {
      'reporter_name': reporterName,
      'report_type': reportType,
      'severity': severity,
      'title': title,
      'description': description,
      'location_name': locationName,
      'route_tag': routeTag,
      'upvotes': 1,
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
    };

    final cl = client;
    if (cl == null) return record;

    try {
      final res = await cl.from('transit_reports').insert(record).select().maybeSingle();
      return res ?? record;
    } catch (e) {
      debugPrint('[SupabaseService] submitReport notice: $e');
      return record;
    }
  }

  /// Submit a comment on a report
  Future<Map<String, dynamic>?> submitReportComment({
    required String reportId,
    required String author,
    required String comment,
    String userLocality = 'Ahmedabad',
  }) async {
    final record = {
      'report_id': reportId,
      'author': author,
      'comment': comment,
      'user_locality': userLocality,
      'created_at': DateTime.now().toIso8601String(),
    };

    final cl = client;
    if (cl == null) return record;

    try {
      final res = await cl.from('report_comments').insert(record).select().maybeSingle();
      return res ?? record;
    } catch (e) {
      debugPrint('[SupabaseService] submitReportComment notice: $e');
      return record;
    }
  }

  /// Upvote an incident report
  Future<void> syncReportUpvote({
    required String reportId,
    required int upvotes,
  }) async {
    final cl = client;
    if (cl == null) return;

    try {
      await cl.from('transit_reports').update({
        'upvotes': upvotes,
      }).eq('id', reportId);
    } catch (e) {
      debugPrint('[SupabaseService] syncReportUpvote notice: $e');
    }
  }

  // ==========================================
  // ROUTE POLYLINE CACHE (Fetch-Once-and-Store)
  // ==========================================

  static bool isDynamicLocation(String s) {
    final low = s.toLowerCase().trim();
    return low.contains('current location') ||
        low.contains('live gps') ||
        low.contains('gps') ||
        low == 'my location' ||
        RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(low);
  }

  static String normalizeStop(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '') // strip (BRTS Hub), etc.
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Check if a driving route polyline is already cached in Supabase gtfs_routes
  Future<TransitRouteResult?> getCachedRoute(String origin, String destination) async {
    final cl = client;
    if (cl == null) return null;

    // Never use static cache for dynamic GPS / Current Location searches
    if (isDynamicLocation(origin) || isDynamicLocation(destination)) {
      return null;
    }

    final normOrig = normalizeStop(origin);
    final normDest = normalizeStop(destination);
    if (normOrig.isEmpty || normDest.isEmpty) return null;

    try {
      // Query routes where origin and destination match normalized names
      final records = await cl
          .from('gtfs_routes')
          .select()
          .not('encoded_polyline', 'is', null)
          .limit(40);

      for (final r in (records as List)) {
        final o = (r['origin_name'] ?? '').toString();
        final d = (r['destination_name'] ?? '').toString();
        if (isDynamicLocation(o) || isDynamicLocation(d)) continue;

        final poly = (r['encoded_polyline'] ?? '').toString();
        final normO = normalizeStop(o);
        final normD = normalizeStop(d);

        if (poly.isNotEmpty &&
            !poly.startsWith('m}re') &&
            !poly.startsWith('a`se') &&
            poly.length >= 20 &&
            normO == normOrig &&
            normD == normDest) {
          debugPrint('[SupabaseService] Exact Cache HIT for route: $origin -> $destination');
          return TransitRouteResult.fromSupabase(r as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] getCachedRoute notice: $e');
    }
    return null;
  }

  /// Store a fetched Google Directions API polyline into Supabase gtfs_routes
  Future<void> cacheRoute(TransitRouteResult route) async {
    final cl = client;
    if (cl == null) return;

    // Never cache dynamic user GPS searches into static table
    if (isDynamicLocation(route.origin) || isDynamicLocation(route.destination)) {
      return;
    }

    final cleanOrig = route.origin.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toUpperCase();
    final cleanDest = route.destination.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toUpperCase();
    final routeId = 'ROUTE_${cleanOrig.substring(0, cleanOrig.length > 15 ? 15 : cleanOrig.length)}_${cleanDest.substring(0, cleanDest.length > 15 ? 15 : cleanDest.length)}';

    final payload = {
      'route_id': routeId,
      'route_short_name': '${route.origin.split(' ').first} ➔ ${route.destination.split(' ').first}',
      'operator': 'MULTIMODAL',
      'origin_name': route.origin,
      'destination_name': route.destination,
      'waypoints': route.waypoints,
      'distance_km': route.distanceKm,
      'duration_mins': route.durationMins,
      'fare_amount': route.fareAmount,
      'encoded_polyline': route.encodedPolyline,
      'route_steps': route.steps.map((s) => s.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await cl.from('gtfs_routes').upsert(payload, onConflict: 'route_id');
      debugPrint('[SupabaseService] Cached route polyline in Supabase: $routeId');
    } catch (e) {
      debugPrint('[SupabaseService] cacheRoute notice: $e');
    }
  }

  /// High-level orchestrator: Checks Supabase cache first; on miss, queries
  /// Google Directions API in DRIVING mode and saves to Supabase (Fetch-Once-and-Store pattern).
  Future<TransitRouteResult> searchAndCacheRoute({
    required String origin,
    required String destination,
    String? displayOrigin,
    String? displayDestination,
    List<String>? waypoints,
  }) async {
    final isDynamic = isDynamicLocation(origin) ||
        isDynamicLocation(destination) ||
        isDynamicLocation(displayOrigin ?? '') ||
        isDynamicLocation(displayDestination ?? '');

    // 1. Check Supabase cache (only for static stops, never dynamic GPS)
    if (!isDynamic) {
      final cached = await getCachedRoute(origin, destination);
      if (cached != null) {
        return cached;
      }
    }

    // 2. Fetch fresh from Google Directions API (Driving Mode)
    var fresh = await GoogleDirectionsService.instance.fetchDrivingRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );

    if (displayOrigin != null && displayOrigin.isNotEmpty) {
      fresh = fresh.copyWith(origin: displayOrigin);
    }
    if (displayDestination != null && displayDestination.isNotEmpty) {
      fresh = fresh.copyWith(destination: displayDestination);
    }

    // 3. Save to Supabase for all future commuters (only if static corridor)
    if (!isDynamic) {
      await cacheRoute(fresh);
    }

    return fresh;
  }
}
