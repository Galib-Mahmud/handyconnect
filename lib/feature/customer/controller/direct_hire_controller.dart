// lib/features/order/controller/direct_hire_controller.dart

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';

// ── List Model ─────────────────────────────────────────────────────
class ProviderModel {
  final int id;
  final String fullName;
  final String categoryName;
  final String? profilePhoto;
  final String? zipCode;
  final bool isVerified;
  final String rating;

  const ProviderModel({
    required this.id,
    required this.fullName,
    required this.categoryName,
    this.profilePhoto,
    this.zipCode,
    required this.isVerified,
    required this.rating,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id          : json['id'] as int,
      fullName    : (json['full_name'] as String?) ?? 'Professional',
      categoryName: (json['category_name'] as String?) ?? '',
      profilePhoto: json['profile_photo'] as String?,
      zipCode     : json['zip_code'] as String?,
      isVerified  : (json['is_verified'] as bool?) ?? false,
      rating      : (json['rating'] as String?) ?? '0.00',
    );
  }
}

// ── Detail Model ───────────────────────────────────────────────────
class ProviderDetailModel {
  final int id;
  final String fullName;
  final String email;
  final String bio;
  final String? profilePhoto;
  final String? zipCode;
  final bool isVerified;
  final int radiusKm;
  final int jobsCount;
  final double averageRating;
  final int reviewCount;
  final Map<String, int> ratingBreakdown;
  final List<Map<String, dynamic>> services;
  final List<dynamic> recentReviews;
  final Map<String, dynamic> verificationStatus;

  const ProviderDetailModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.bio,
    this.profilePhoto,
    this.zipCode,
    required this.isVerified,
    required this.radiusKm,
    required this.jobsCount,
    required this.averageRating,
    required this.reviewCount,
    required this.ratingBreakdown,
    required this.services,
    required this.recentReviews,
    required this.verificationStatus,
  });

  factory ProviderDetailModel.fromJson(Map<String, dynamic> json) {
    // Parse rating breakdown
    final rawBreakdown = json['rating_breakdown'];
    final Map<String, int> breakdown = {};
    if (rawBreakdown is Map) {
      for (final e in rawBreakdown.entries) {
        breakdown[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
      }
    }

    return ProviderDetailModel(
      id               : json['id'] as int,
      fullName         : (json['full_name'] as String?) ?? 'Professional',
      email            : (json['email'] as String?) ?? '',
      bio              : (json['bio'] as String?) ?? '',
      profilePhoto     : json['profile_photo'] as String?,
      zipCode          : json['zip_code'] as String?,
      isVerified       : (json['is_verified'] as bool?) ?? false,
      radiusKm         : (json['radius_km'] as num?)?.toInt() ?? 0,
      jobsCount        : (json['jobs_count'] as num?)?.toInt() ?? 0,
      averageRating    : (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount      : (json['review_count'] as num?)?.toInt() ?? 0,
      ratingBreakdown  : breakdown,
      services         : (json['services'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
          [],
      recentReviews    : (json['recent_reviews'] as List?) ?? [],
      verificationStatus: (json['verification_status'] is Map)
          ? Map<String, dynamic>.from(json['verification_status'] as Map)
          : {},
    );
  }
}

// ── Controller ─────────────────────────────────────────────────────
class DirectHireController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final int serviceId;
  final int requestId;

  DirectHireController({
    required this.serviceId,
    required this.requestId,
  });

  // ── State ──────────────────────────────────────────────────────────
  final RxList<ProviderModel> providers  = <ProviderModel>[].obs;
  final RxBool isLoadingProviders        = false.obs;
  final RxBool isLoadingDetails          = false.obs;
  final RxBool isSending                 = false.obs;
  final RxString errorMessage            = ''.obs;

  // Currently viewed provider details (for popup)
  final Rx<ProviderDetailModel?> selectedProvider = Rx(null);

  @override
  void onInit() {
    super.onInit();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏗️  [DIRECT HIRE] Controller initialised');
    print('   serviceId : $serviceId');
    print('   requestId : $requestId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    fetchProviders();
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 1 — GET /services/providers/?service_id=X
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchProviders() async {
    try {
      isLoadingProviders.value = true;
      errorMessage.value = '';

      final endpoint = serviceId > 0
          ? '${ApiEndpoint.provider}?service_id=$serviceId'
          : ApiEndpoint.provider;

      print('📡 [DIRECT HIRE] GET $endpoint');

      final res = await _apiClient.get(endpoint, requiresAuth: true);

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      providers.assignAll(
        raw.map((e) =>
            ProviderModel.fromJson(Map<String, dynamic>.from(e as Map))),
      );

      print('✅ [DIRECT HIRE] ${providers.length} provider(s) loaded');
    } on HttpException catch (e) {
      print('❌ [DIRECT HIRE] Providers error: ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [DIRECT HIRE] Providers error: $e');
      errorMessage.value = 'Could not load professionals.';
      Get.snackbar('Error', 'Could not load professionals.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingProviders.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — GET /services/providers/{id}/  (for popup)
  // ─────────────────────────────────────────────────────────────────
  Future<ProviderDetailModel?> fetchProviderDetails(int providerId) async {
    try {
      isLoadingDetails.value = true;
      selectedProvider.value = null;

      print('📡 [DIRECT HIRE] GET provider details: $providerId');

      final res = await _apiClient.get(
        ApiEndpoint.providerDetails(providerId),
        requiresAuth: true,
      );

      final detail = ProviderDetailModel.fromJson(
          Map<String, dynamic>.from(res as Map));

      selectedProvider.value = detail;
      print('✅ [DIRECT HIRE] Provider detail loaded: ${detail.fullName}');
      return detail;
    } on HttpException catch (e) {
      print('❌ [DIRECT HIRE] Detail error: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (e) {
      print('❌ [DIRECT HIRE] Detail error: $e');
      Get.snackbar('Error', 'Could not load details.',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isLoadingDetails.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3 — POST /services/providers/{id}/invite/
  // Body: { "request_id": N }
  // ─────────────────────────────────────────────────────────────────
  Future<void> inviteProvider(int providerId, String providerName) async {
    if (isSending.value) return;

    if (requestId == 0) {
      Get.snackbar('Error', 'No active request found.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSending.value = true;

      print('📡 [DIRECT HIRE] POST invite provider $providerId');
      print('   endpoint : ${ApiEndpoint.inviteProvider(providerId)}');
      print('   body     : { "request_id": $requestId }');

      final response = await _apiClient.post(
        ApiEndpoint.inviteProvider(providerId),
        body: {'request_id': requestId},
        requiresAuth: true,
      );

      print('✅ [DIRECT HIRE] Invite sent to $providerName');
      print('   response: $response');

      Get.snackbar('Sent!', 'Request sent to $providerName',
          snackPosition: SnackPosition.BOTTOM);

      Get.toNamed(RouteName.customerinProgress);
    } on HttpException catch (e) {
      print('❌ [DIRECT HIRE] Invite error: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [DIRECT HIRE] Invite error: $e');
      Get.snackbar('Error', 'Could not send request.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }
}