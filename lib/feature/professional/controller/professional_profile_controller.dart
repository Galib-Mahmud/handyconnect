import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';


// ── Service model ───────────────────────────────────────────────────
class ProviderService {
  final int id;
  final String nameEn;
  final String icon;
  final String minPrice;
  final String maxPrice;

  const ProviderService({
    required this.id,
    required this.nameEn,
    required this.icon,
    required this.minPrice,
    required this.maxPrice,
  });

  factory ProviderService.fromJson(Map<String, dynamic> j) => ProviderService(
    id: j['id'] as int? ?? 0,
    nameEn: (j['name_en'] as String?) ?? '',
    icon: (j['icon'] as String?) ?? '',
    minPrice: (j['min_price'] ?? '').toString(),
    maxPrice: (j['max_price'] ?? '').toString(),
  );
}

// ── Received Review Model ──────────────────────────────────────────
class ReceivedReviewModel {
  final int id;
  final String customerName;
  final String? customerPhoto;
  final double rating;
  final String comment;
  final String createdAt;

  const ReceivedReviewModel({
    required this.id,
    required this.customerName,
    this.customerPhoto,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReceivedReviewModel.fromJson(Map<String, dynamic> j) {
    final rawPhoto = (j['customer_photo'] ?? j['avatar'] ?? j['user_photo']) as String?;
    return ReceivedReviewModel(
      id: (j['id'] as int?) ?? 0,
      customerName: (j['customer_name'] ?? j['customer']?['full_name'] ?? j['reviewer_name'] ?? 'Customer').toString(),
      customerPhoto: (rawPhoto != null && rawPhoto.isNotEmpty) ? ApiEndpoint.mediaUrl(rawPhoto) : null,
      rating: double.tryParse((j['rating'] ?? '5').toString()) ?? 5.0,
      comment: (j['comment'] ?? j['review'] ?? '').toString(),
      createdAt: (j['created_at_human'] ?? j['created_at'] ?? '').toString(),
    );
  }
}

class ProfessionalProfileController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Tabs ───────────────────────────────────────────────────────
  final selectedTab = 0.obs;

  // ── Loading ────────────────────────────────────────────────────
  final isLoading = false.obs;
  final errorMsg  = ''.obs;

  // ── Profile data ───────────────────────────────────────────────
  final name         = ''.obs;
  final email        = ''.obs;
  final bio          = ''.obs;
  final photo        = ''.obs;
  final radiusKm     = 0.obs;
  final jobsCount    = 0.obs;
  final rating       = 0.0.obs;
  final reviewCount  = 0.obs;
  final isVerified   = false.obs;

  // ── Rating breakdown {5:0, 4:0, ...} ───────────────────────────
  final ratingBreakdown = <String, int>{}.obs;

  // ── Reviews received (GET /api/services/reviews/received/) ───────
  final receivedReviews = <ReceivedReviewModel>[].obs;
  final isLoadingReviews = false.obs;

  // ── Services (deduplicated) ────────────────────────────────────
  final services = <ProviderService>[].obs;

  // ── Verification status ────────────────────────────────────────
  final govIdVerified   = false.obs;
  final certVerified    = false.obs;
  final photoVerified   = false.obs;
  final trustScore      = 0.obs;

  // ── Loading states for actions ─────────────────────────────────
  final isLogoutLoading = false.obs;
  final isDeleteChecked = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    fetchReceivedReviews();
  }

  void selectTab(int index) => selectedTab.value = index;

  // ─────────────────────────────────────────────────────────────────
  // GET /services/providers/{id}/
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchProfile() async {
    final providerId = UserInfo.getProviderIdSync() ?? 0;
    if (providerId == 0) {
      errorMsg.value = 'Profile not available.';
      print('❌ [PROFILE] No provider id in UserInfo');
      return;
    }

    try {
      isLoading.value = true;
      errorMsg.value = '';

      print('📡 [PROFILE] GET providers/$providerId/');

      final res = await _apiClient.get(
        ApiEndpoint.providerDetails(providerId), // /services/providers/{id}/
        requiresAuth: true,
      ) as Map<String, dynamic>;

      name.value        = (res['full_name'] as String?) ?? 'Professional';
      email.value       = (res['email'] as String?) ?? '';
      bio.value         = (res['bio'] as String?) ?? '';
      final rawPhoto    = (res['profile_photo'] as String?) ?? '';
      photo.value       = ApiEndpoint.mediaUrl(rawPhoto);
      radiusKm.value    = (res['radius_km'] as num?)?.toInt() ?? 0;
      jobsCount.value   = (res['jobs_count'] as num?)?.toInt() ?? 0;
      rating.value      = (res['average_rating'] as num?)?.toDouble() ?? 0.0;
      reviewCount.value = (res['review_count'] as num?)?.toInt() ?? 0;
      isVerified.value  = (res['is_verified'] as bool?) ?? false;

      // Rating breakdown
      final rb = res['rating_breakdown'];
      final Map<String, int> breakdown = {};
      if (rb is Map) {
        for (final e in rb.entries) {
          breakdown[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
        }
      }
      ratingBreakdown.assignAll(breakdown);

      // Services — deduplicate by name_en
      final rawServices = (res['services'] as List?) ?? [];
      final seen = <String>{};
      final unique = <ProviderService>[];
      for (final s in rawServices) {
        final svc = ProviderService.fromJson(Map<String, dynamic>.from(s as Map));
        if (svc.nameEn.isNotEmpty && seen.add(svc.nameEn)) {
          unique.add(svc);
        }
      }
      services.assignAll(unique);

      // Verification status
      final vs = res['verification_status'];
      if (vs is Map) {
        govIdVerified.value = vs['government_id'] == true;
        certVerified.value  = vs['professional_certificate'] == true;
        photoVerified.value = vs['profile_photo'] == true;
        trustScore.value    = (vs['trust_score'] as num?)?.toInt() ?? 0;
      }

      print('✅ [PROFILE] Loaded: ${name.value}');
    } on HttpException catch (e) {
      print('❌ [PROFILE] HttpException: ${e.message}');
      errorMsg.value = e.message;
    } catch (e) {
      print('❌ [PROFILE] Error: $e');
      errorMsg.value = 'Could not load profile.';
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /api/services/reviews/received/
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchReceivedReviews() async {
    try {
      isLoadingReviews.value = true;
      print('⭐ [REVIEWS RECEIVED] GET /services/reviews/received/');
      final res = await _apiClient.get(
        ApiEndpoint.reviewsReceived,
        requiresAuth: true,
      );
      final List<dynamic> list = res is List ? res : (res['results'] as List? ?? []);
      receivedReviews.assignAll(
        list.map((e) => ReceivedReviewModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
      print('✅ [REVIEWS RECEIVED] Loaded ${receivedReviews.length} review(s)');
    } catch (e) {
      print('❌ [REVIEWS RECEIVED] Error: $e');
    } finally {
      isLoadingReviews.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /api/auth/me/
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchCurrentUser() async {
    try {
      final res = await _apiClient.get(ApiEndpoint.authMe, requiresAuth: true);
      if (res != null) {
        if (res['full_name'] != null) {
          name.value = res['full_name'];
          await UserInfo.setFullName(res['full_name']);
        }
        if (res['email'] != null) email.value = res['email'];
      }
    } catch (e) {
      print('❌ fetchCurrentUser error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PATCH /api/auth/me/
  // ─────────────────────────────────────────────────────────────────
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? language,
  }) async {
    try {
      isLoading.value = true;
      final body = <String, dynamic>{
        if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
        if (language != null && language.trim().isNotEmpty) 'language': language.trim(),
      };

      final res = await _apiClient.patch(
        ApiEndpoint.authMe,
        body: body,
        requiresAuth: true,
      );

      if (res != null) {
        if (res['full_name'] != null) {
          name.value = res['full_name'];
          await UserInfo.setFullName(res['full_name']);
        }
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
      return true;
    } on HttpException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile.', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    isLogoutLoading.value = true;
    try {
      final refreshToken = await UserInfo.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          ApiEndpoint.logout,
          body: {'refresh': refreshToken},
          requiresAuth: true,
        );
      }
    } catch (e) {
      print('⚠️ Logout API error (ignored): $e');
    } finally {
      isLogoutLoading.value = false;
      await UserInfo.clearAll();
      Get.offAllNamed(RouteName.signin);
    }
  }

  void showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF757575))),
          ),
          Obx(() => TextButton(
            onPressed: isLogoutLoading.value ? null : logout,
            child: isLogoutLoading.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE53935),
              ),
            )
                : const Text('Log Out',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                )),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE ACCOUNT
  // ─────────────────────────────────────────────────────────────────
  void toggleDeleteCheck(bool? val) => isDeleteChecked.value = val ?? false;

  void showDeleteAccountDialog(BuildContext context) {
    isDeleteChecked.value = false;
    Get.dialog(
      _DeleteAccountDialog(controller: this),
      barrierDismissible: false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    if (!isDeleteChecked.value) return;
    Get.back();
    try {
      await _apiClient.delete(ApiEndpoint.deleteAccount, requiresAuth: true);
      await UserInfo.clearAll();
      Get.offAllNamed(RouteName.signin);
      Get.snackbar(
        'success'.tr,
        'delete_account_success'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
    } on HttpException catch (e) {
      print('❌ Delete account failed: ${e.message}');
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF5350),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Delete account error: $e');
      Get.snackbar(
        'Error',
        'Could not delete account. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF5350),
        colorText: Colors.white,
      );
    }
  }
}

// ─────────────────── Delete Account Dialog ───────────────────────
class _DeleteAccountDialog extends StatelessWidget {
  final ProfessionalProfileController controller;

  const _DeleteAccountDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close,
                      color: Color(0xFF9E9E9E), size: 22),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFE53935), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Account',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF212121))),
              const SizedBox(height: 10),
              const Text(
                'This will permanently delete your account and all associated data. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFB45309), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Under GDPR (Art. 17), you have the right to erasure. Deleting your account will remove all personal data we hold about you within 30 days.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => GestureDetector(
                onTap: () => controller
                    .toggleDeleteCheck(!controller.isDeleteChecked.value),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: controller.isDeleteChecked.value
                            ? const Color(0xFF1565C0)
                            : Colors.white,
                        border: Border.all(
                          color: controller.isDeleteChecked.value
                              ? const Color(0xFF1565C0)
                              : const Color(0xFFBDBDBD),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: controller.isDeleteChecked.value
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I understand this is permanent and irreversible',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF212121)),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              Obx(() => GestureDetector(
                onTap: controller.isDeleteChecked.value
                    ? controller.confirmDeleteAccount
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: controller.isDeleteChecked.value
                        ? const Color(0xFFE53935)
                        : const Color(0xFFEF9A9A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Delete My Account',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              )),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: const Color(0xFFEEEEEE), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}