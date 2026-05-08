// lib/features/professional/home/controllers/professional_home_controller.dart

import 'dart:io';

import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';



class ProfessionalHomeController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isOnline  = false.obs;

  // ── Profile ───────────────────────────────────────────────────────
  // All sourced from response['profile'] inside /services/requests/pro/homepage/
  final RxString professionalName  = ''.obs;
  final RxString professionalImage = ''.obs;
  final RxString professionalEmail = ''.obs;
  final RxString professionalBio   = ''.obs;
  final RxBool   isVerified        = false.obs;
  final RxBool   isAvailable       = false.obs;
  final RxInt    certificates      = 0.obs;

  // ── Stats ─────────────────────────────────────────────────────────
  final RxInt    emergencyCount = 0.obs;
  final RxInt    jobsCount      = 0.obs;
  final RxDouble rating         = 0.0.obs;

  // ── Lists ─────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> activeJobs        = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> emergencyRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> newRequests       = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> privateRequests   = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomepage(); // single call — profile is embedded inside this response
  }

  // ── Fetch Homepage (profile + stats + lists) ──────────────────────
  Future<void> fetchHomepage() async {
    try {
      isLoading.value = true;

      print('🏠 [PRO HOME] Fetching /services/requests/pro/homepage/ ...');

      final response = await _apiClient.get(ApiEndpoint.proHomepage);

      print('✅ [PRO HOME] Response received');

      // ── Profile block ─────────────────────────────────────────────
      // JSON shape:
      // "profile": { "full_name", "email", "photo", "bio",
      //              "emergency_count", "jobs_count", "rating",
      //              "certificates", "is_verified", "is_available" }
      final profile = (response['profile'] as Map?)?.cast<String, dynamic>() ?? {};

      professionalName.value  = profile['full_name']    ?? 'Professional';
      professionalEmail.value = profile['email']         ?? '';
      professionalBio.value   = profile['bio']           ?? '';
      isVerified.value        = profile['is_verified']   ?? false;
      isAvailable.value       = profile['is_available']  ?? false;
      certificates.value      = profile['certificates']  ?? 0;

      // photo is a relative path like "/media/providers/photos/..."
      // prepend base URL so Image.network can load it correctly
      final rawPhoto = (profile['photo'] as String?) ?? '';
      professionalImage.value = rawPhoto.isNotEmpty
          ? '${ApiEndpoint.baseUrl}$rawPhoto'
          : '';

      final profileRating =
          double.tryParse(profile['rating']?.toString() ?? '0') ?? 0.0;

      print('👤 Name  : ${professionalName.value}');
      print('📸 Photo : ${professionalImage.value}');
      print('✉️  Email : ${professionalEmail.value}');

      // ── Online status ─────────────────────────────────────────────
      isOnline.value = response['is_online'] ?? false;

      // ── Stats block ───────────────────────────────────────────────
      // JSON shape: "stats": { "emergency_count", "active_jobs_count", "rating" }
      // Falls back to profile-level counts if stats are missing
      final stats = (response['stats'] as Map?)?.cast<String, dynamic>() ?? {};

      emergencyCount.value = stats['emergency_count']  ?? profile['emergency_count'] ?? 0;
      jobsCount.value      = stats['active_jobs_count'] ?? profile['jobs_count']      ?? 0;

      final statsRating =
          double.tryParse(stats['rating']?.toString() ?? '0') ?? 0.0;
      // prefer stats rating; fall back to profile rating
      rating.value = statsRating > 0 ? statsRating : profileRating;

      // ── Request lists ─────────────────────────────────────────────
      // _normalizeRequest converts ai_cost Map → formatted String
      activeJobs.value = _parseList(response['active_jobs']);
      emergencyRequests.value = _parseList(response['emergency_requests']);
      newRequests.value = _parseList(response['new_requests']);
      privateRequests.value = _parseList(response['private_requests']);

      print('🔧 Active Jobs        : ${activeJobs.length}');
      print('🚨 Emergency Requests : ${emergencyRequests.length}');
      print('🆕 New Requests       : ${newRequests.length}');
      print('🔒 Private Requests   : ${privateRequests.length}');

    } on HttpException catch (e) {
      print('❌ [PRO HOME] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [PRO HOME] Error: $e');
      Get.snackbar('Error', 'Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Parse a raw list from the API response ────────────────────────
  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => _normalizeRequest(e)),
    );
  }

  // ── Normalize a single request map ───────────────────────────────
  /// Converts ai_cost from Map → pre-formatted String so the UI never
  /// gets a Map where it expects a String.
  /// Prevents: type '_Map<String, dynamic>' is not a subtype of type 'String'
  Map<String, dynamic> _normalizeRequest(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    map['ai_cost'] = _formatAiCost(map['ai_cost']);
    return map;
  }

  // ── Format ai_cost object → display string ────────────────────────
  /// API sends: { "min": 160, "max": 380, "currency": "EUR" }
  /// Result   : "EUR 160 – 380"
  static String _formatAiCost(dynamic aiCost) {
    if (aiCost == null) return '—';
    if (aiCost is String) return aiCost.isNotEmpty ? aiCost : '—';
    if (aiCost is Map) {
      final min      = aiCost['min'];
      final max      = aiCost['max'];
      final currency = aiCost['currency'] ?? '';
      if (min != null && max != null) return '$currency $min – $max';
      if (min != null) return '$currency $min';
      if (max != null) return '$currency $max';
    }
    return '—';
  }

  // ── Toggle Online ─────────────────────────────────────────────────
  void toggleOnline(bool val) {
    isOnline.value = val;
    print('🔄 [ONLINE STATUS] Changed to: $val');
    // TODO: call PATCH /services/providers/toggle-online/ if API exists
  }

  // ── Helper: icon string → asset path ─────────────────────────────
  static String assetFromIcon(String icon) {
    const map = {
      'water_drop'     : 'assets/images/profile/water.png',
      'bolt'           : 'assets/images/profile/2.png',
      'ac_unit'        : 'assets/images/profile/3.png',
      'palette'        : 'assets/images/profile/7.png',
      'local_shipping' : 'assets/images/profile/8.png',
      'eco'            : 'assets/images/profile/12.png',
    };
    return map[icon] ?? 'assets/images/profile/water.png';
  }
}