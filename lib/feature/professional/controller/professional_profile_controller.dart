import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';

class ReviewModel {
  final String initials;
  final Color color;
  final String name;
  final int stars;
  final String comment;

  const ReviewModel({
    required this.initials,
    required this.color,
    required this.name,
    required this.stars,
    required this.comment,
  });
}

class ProfessionalProfileController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Tabs ───────────────────────────────────────────────────────
  final selectedTab = 0.obs;

  // ── Profile ────────────────────────────────────────────────────
  final name        = 'Michael Ben'.obs;
  final email       = 'michealben@gmail.com'.obs;
  final radiusKm    = '10km'.obs;
  final totalJobs   = 342.obs;
  final rating      = 4.2.obs;

  // ── Loading states ─────────────────────────────────────────────
  final isLogoutLoading = false.obs;
  final isDeleteChecked = false.obs;

  // ── Reviews ────────────────────────────────────────────────────
  final reviews = <ReviewModel>[
    const ReviewModel(
      initials: 'DC',
      color: Color(0xFF00ACC1),
      name: 'David Cohen',
      stars: 4,
      comment: 'Excellent work, very professional!',
    ),
    const ReviewModel(
      initials: 'SL',
      color: Color(0xFFE53935),
      name: 'Sarah Levi',
      stars: 4,
      comment: 'Fixed the issue quickly. Highly recommend!',
    ),
  ].obs;

  void selectTab(int index) => selectedTab.value = index;

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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
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
  // DELETE ACCOUNT
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
    Get.back();
    // TODO: call DELETE /auth/delete-account/ endpoint
    await UserInfo.clearAll();
    Get.offAllNamed(RouteName.signin);
  }
}

// ─────────────────── Delete Account Dialog ───────────────────────
class _DeleteAccountDialog extends StatelessWidget {
  final ProfessionalProfileController controller;

  const _DeleteAccountDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              const Text(
                'Delete Account',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121)),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will permanently delete your account and all associated data. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.5),
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
                          ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I understand this is permanent and irreversible',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF212121)),
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
                    border: Border.all(
                        color: const Color(0xFFEEEEEE), width: 1),
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