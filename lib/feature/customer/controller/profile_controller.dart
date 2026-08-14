// lib/feature/customer/profile/controllers/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';


// ─── Category model ───────────────────────────────────────────────
class CategoryModel {
  final int id;
  final String nameEn;
  final String nameDe;
  final String icon;
  final String color;
  final String minPrice;
  final String maxPrice;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.icon,
    required this.color,
    required this.minPrice,
    required this.maxPrice,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] ?? 0,
    nameEn: json['name_en'] ?? '',
    nameDe: json['name_de'] ?? '',
    icon: json['icon'] ?? '',
    color: json['color'] ?? '#000000',
    minPrice: json['min_price'] ?? '0',
    maxPrice: json['max_price'] ?? '0',
    isActive: json['is_active'] ?? false,
  );
}

// ─── ProfileController ────────────────────────────────────────────
class ProfileController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── State ──────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isLogoutLoading = false.obs;

  // ── Profile fields ─────────────────────────────────────────────
  final RxInt userId = 0.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userRole = ''.obs;
  final RxBool isVerified = false.obs;

  // ── Categories from homepage ───────────────────────────────────
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  // ── Recent requests ────────────────────────────────────────────
  final RxList recentRequests = [].obs;

  // ── Delete account dialog ──────────────────────────────────────
  final RxBool isDeleteChecked = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomerHomepage();
  }

  // ─────────────────────────────────────────────────────────────────
  // FETCH CUSTOMER HOMEPAGE
  // GET /api/services/requests/customer/homepage/
  // Response: profile{}, recent_requests[], categories[]
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchCustomerHomepage() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.get(
        ApiEndpoint.customerHomepage,
        requiresAuth: true,
      );

      if (response != null) {
        // ── Parse profile ────────────────────────────────────────
        final profile = response['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          userId.value    = profile['id'] ?? 0;
          userEmail.value = profile['email'] ?? '';
          userName.value  = profile['full_name'] ?? '';
          userPhone.value = profile['phone_number'] ?? '';
          userRole.value  = profile['role'] ?? '';
          isVerified.value = profile['is_verified'] ?? false;
        }

        // ── Parse categories ─────────────────────────────────────
        final cats = response['categories'] as List<dynamic>? ?? [];
        categories.value = cats
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // ── Parse recent requests ────────────────────────────────
        recentRequests.value =
            (response['recent_requests'] as List<dynamic>?) ?? [];
      }
    } on HttpException catch (e) {
      _showError(e.message);
    } catch (e) {
      print('❌ fetchCustomerHomepage error: $e');
      _showError('Failed to load profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGOUT
  // POST /auth/logout/
  // Body: { "refresh": "<refresh_token>" }
  // ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    isLogoutLoading.value = true;
    try {
      final refreshToken = await UserInfo.getRefreshToken();

      // Hit logout endpoint to blacklist the refresh token on backend
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          ApiEndpoint.logout,
          body: {'refresh': refreshToken},
          requiresAuth: true,
        );
      }
    } catch (e) {
      // Even if the API call fails (e.g. token already expired),
      // we still clear local storage and navigate to SignIn.
      print('⚠️ Logout API error (ignored): $e');
    } finally {
      isLogoutLoading.value = false;
      await UserInfo.clearAll();
      Get.offAllNamed(RouteName.signin);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // DELETE ACCOUNT DIALOG HELPERS
  // ─────────────────────────────────────────────────────────────────
  void toggleDeleteCheck(bool? val) {
    isDeleteChecked.value = val ?? false;
  }

  void showDeleteAccountDialog(BuildContext context) {
    isDeleteChecked.value = false;
    Get.dialog(
      _DeleteAccountDialog(controller: this),
      barrierDismissible: false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    if (!isDeleteChecked.value) return;
    Get.back(); // close dialog
    // TODO: call DELETE /auth/delete-account/ endpoint
    // After success → clearAll + navigate to SignIn
    await UserInfo.clearAll();
    Get.offAllNamed(RouteName.signin);
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGOUT DIALOG
  // ─────────────────────────────────────────────────────────────────
  void showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF757575)),
            ),
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
                : const Text(
              'Log Out',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SNACKBARS
  // ─────────────────────────────────────────────────────────────────
  void _showError(String message) {
    Get.snackbar(
      "Error", message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );
  }
}

// ─────────────────── Delete Account Dialog ─────────────────────────
class _DeleteAccountDialog extends StatelessWidget {
  final ProfileController controller;

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
                  child: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 22),
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
                child: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF212121)),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will permanently delete your account and all associated data. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
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
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Under GDPR (Art. 17), you have the right to erasure. Deleting your account will remove all personal data we hold about you within 30 days.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => GestureDetector(
                onTap: () => controller.toggleDeleteCheck(
                    !controller.isDeleteChecked.value),
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
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I understand this is permanent and irreversible',
                        style: TextStyle(fontSize: 13, color: Color(0xFF212121)),
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
                  child: const Text(
                    'Delete My Account',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
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
                    border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}