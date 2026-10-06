import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';

class ReportIssueController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final additionalDetailsController = TextEditingController();
  final selectedReason = 0.obs; // 0 = Ghost Lead, 1 = Bad Lead, 2 = Other
  final RxBool isSubmitting = false.obs;

  final reasons = [
    'Ghost Lead - No response from customer',
    'Bad Lead - Incorrect information',
    'Other',
  ];

  @override
  void onClose() {
    additionalDetailsController.dispose();
    super.onClose();
  }

  void selectReason(int index) => selectedReason.value = index;

  Future<void> submitReport() async {
    isSubmitting.value = true;
    try {
      final reason = reasons[selectedReason.value];
      final details = additionalDetailsController.text.trim();
      await _apiClient.post(
        ApiEndpoint.support,
        body: {
          'reason': reason,
          'details': details,
          'message': '$reason: $details',
        },
        requiresAuth: true,
      );
      Get.back();
      Get.snackbar(
        'success'.tr,
        'report_submitted'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'info'.tr,
        'report_submitted'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}