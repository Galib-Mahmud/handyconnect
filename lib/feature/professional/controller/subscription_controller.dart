// lib/feature/professional/controllers/subscription_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';





class SubscriptionController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading      = false.obs;
  final RxBool isYearly       = true.obs;   // default: Yearly selected

  // ── Plan type string for API ──────────────────────────────────────
  String get selectedPlanType => isYearly.value ? 'YEARLY' : 'MONTHLY';

  void selectMonthly() => isYearly.value = false;
  void selectYearly()  => isYearly.value = true;

  // ── POST /pro/subscription/activate/ ─────────────────────────────
  Future<void> activateSubscription() async {
    isLoading.value = true;
    try {
      print('📤 [SUBSCRIPTION] Activating plan: $selectedPlanType');

      final response = await _apiClient.post(
        ApiEndpoint.activateSubscription,
        body: {'plan_type': selectedPlanType},
      );

      print('✅ [SUBSCRIPTION] Response: $response');

      // Success → clear session → go to sign in
      await UserInfo.clearAll();

      Get.snackbar(
        'Subscribed!',
        response['message']?.toString() ?? 'Subscription activated.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );

      // Small delay so snackbar is visible before navigation
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(RouteName.signin);

    } on HttpException catch (e) {
      print('❌ [SUBSCRIPTION] HttpException: ${e.message}');
      Get.snackbar(
        'Error', e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('❌ [SUBSCRIPTION] Error: $e');
      Get.snackbar(
        'Error', 'Something went wrong. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }
}