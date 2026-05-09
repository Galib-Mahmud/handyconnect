// lib/features/order/controller/direct_hire_controller.dart

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';          // adjust to your route path

// ── Model ──────────────────────────────────────────────────────────
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
      id          : json['id']            as int,
      fullName    : (json['full_name']     as String?) ?? '',
      categoryName: (json['category_name'] as String?) ?? '',
      profilePhoto: json['profile_photo']  as String?,
      zipCode     : json['zip_code']       as String?,
      isVerified  : (json['is_verified']   as bool?)   ?? false,
      rating      : (json['rating']        as String?) ?? '0.00',
    );
  }
}

// ── Controller ─────────────────────────────────────────────────────
class DirectHireController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── State ──────────────────────────────────────────────────────────
  final RxList<ProviderModel> providers = <ProviderModel>[].obs;
  final RxBool isLoadingProviders       = false.obs;
  final RxBool isSending                = false.obs;
  final RxString errorMessage           = ''.obs;

  // requestId saved by ConfirmRequestScreen via UserInfo.setRequestId()
  int get _requestId => UserInfo.getRequestIdSync() ?? 0;

  @override
  void onInit() {
    super.onInit();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏗️  [DIRECT HIRE] Controller initialised');
    print('   requestId from UserInfo: $_requestId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // STEP 1 — fetch providers as soon as screen opens
    fetchProviders();
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 1 — GET /services/providers/
  // Called automatically on screen open.
  // The Send Request button is disabled while this is loading.
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchProviders() async {
    try {
      isLoadingProviders.value = true;
      errorMessage.value       = '';

      print('');
      print('📡 [DIRECT HIRE] ── STEP 1: GET providers ──────────────');
      print('   endpoint : ${ApiEndpoint.provider}');
      print('   token    : ${_tokenPreview()}');

      final res = await _apiClient.get(
        ApiEndpoint.provider,   // → /services/providers/
        requiresAuth: true,
      );

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      providers.assignAll(
        raw.map((e) =>
            ProviderModel.fromJson(Map<String, dynamic>.from(e as Map))),
      );

      print('✅ [DIRECT HIRE] STEP 1 SUCCESS — ${providers.length} provider(s):');
      for (final p in providers) {
        print('   [${p.id}] ${p.fullName}'
            ' | verified: ${p.isVerified}'
            ' | zip: ${p.zipCode ?? "—"}'
            ' | rating: ${p.rating}'
            ' | photo: ${p.profilePhoto ?? "none"}');
      }
      print('────────────────────────────────────────────────────────');
    } on HttpException catch (e) {
      print('❌ [DIRECT HIRE] STEP 1 FAILED — HttpException [${e.statusCode}]: ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [DIRECT HIRE] STEP 1 FAILED — unknown: $e');
      errorMessage.value = 'Could not load professionals.';
      Get.snackbar('Error', 'Could not load professionals.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingProviders.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — POST /services/requests/{requestId}/send-offer/
  // Only callable after STEP 1 succeeds (button blocked while loading).
  // On success → navigate to in-progress screen.
  // ─────────────────────────────────────────────────────────────────
  Future<void> sendRequest(int providerId, String providerName) async {
    // Guard: providers must be loaded first
    if (isLoadingProviders.value) {
      print('⚠️  [DIRECT HIRE] STEP 2 blocked — providers still loading');
      Get.snackbar('Please wait', 'Loading professionals…',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Guard: no duplicate taps
    if (isSending.value) {
      print('⚠️  [DIRECT HIRE] STEP 2 blocked — already sending');
      return;
    }

    // Guard: request id must be saved
    if (_requestId == 0) {
      print('⚠️  [DIRECT HIRE] STEP 2 blocked — no requestId in UserInfo');
      Get.snackbar('Error', 'No active request found.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSending.value = true;

      print('');
      print('📡 [DIRECT HIRE] ── STEP 2: POST send-offer ────────────');
      print('   endpoint   : ${ApiEndpoint.sendOffer(_requestId)}');
      print('   requestId  : $_requestId');
      print('   providerId : $providerId');
      print('   provider   : $providerName');
      print('   body       : { "direct_hire_provider_id": $providerId }');
      print('   token      : ${_tokenPreview()}');

      final response = await _apiClient.post(
        ApiEndpoint.sendOffer(_requestId),
        body: {'direct_hire_provider_id': providerId},
        requiresAuth: true,
      );

      print('✅ [DIRECT HIRE] STEP 2 SUCCESS');
      print('   response: $response');
      print('────────────────────────────────────────────────────────');
      print('');
      print('🚀 [DIRECT HIRE] Navigating to in-progress screen...');

      // STEP 3 — navigate immediately after successful POST
      Get.toNamed(RouteName.customerinProgress);

    } on HttpException catch (e) {
      print('❌ [DIRECT HIRE] STEP 2 FAILED — HttpException [${e.statusCode}]: ${e.message}');
      print('   body: ${e.body}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [DIRECT HIRE] STEP 2 FAILED — unknown: $e');
      Get.snackbar('Error', 'Could not send request. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  // ── Token preview for debug (shows first 20 chars only) ───────────
  String _tokenPreview() {
    final token = UserInfo.getAccessTokenSync() ?? '';
    if (token.isEmpty) return 'NO TOKEN';
    return '${token.substring(0, token.length.clamp(0, 20))}…';
  }
}