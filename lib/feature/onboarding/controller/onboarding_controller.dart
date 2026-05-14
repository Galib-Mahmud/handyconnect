// lib/feature/professional/controllers/onboarding_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';
import 'package:image_picker/image_picker.dart';




class OnboardingController extends GetxController {
  static OnboardingController get to =>
      Get.put(OnboardingController(), permanent: true);

  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 3 — Setup Services state
  // ─────────────────────────────────────────────────────────────────
  final RxSet<String> selectedCategories = <String>{}.obs;
  // Map category name → id (matches backend)
  final Map<String, int> categoryIdMap = {
    'Plumbing': 1,
    'Electrical': 2,
    'Ac & HVAC': 3,
    'Painting': 4,
    'Moving': 5,
    'Gardening': 6,
  };

  final RxBool isHourly = true.obs;
  final RxDouble serviceRadius = 15.0.obs;
  final businessAddressController = TextEditingController();

  void toggleCategory(String name) {
    if (selectedCategories.contains(name)) {
      selectedCategories.remove(name);
    } else {
      selectedCategories.add(name);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 2 — Document Upload state
  // ─────────────────────────────────────────────────────────────────
  final Rx<File?> governmentIdFile = Rx<File?>(null);
  final Rx<File?> certificateFile = Rx<File?>(null);
  final Rx<File?> profilePhotoFile = Rx<File?>(null);

  // How many docs uploaded (for progress bar)
  int get uploadedCount {
    int count = 0;
    if (governmentIdFile.value != null) count++;
    if (certificateFile.value != null) count++;
    if (profilePhotoFile.value != null) count++;
    return count;
  }

  /// Returns true if all 3 documents are uploaded, otherwise shows an error.
  bool validateDocuments() {
    if (governmentIdFile.value == null ||
        certificateFile.value == null ||
        profilePhotoFile.value == null) {
      _showError('Please upload all three documents before continuing.');
      return false;
    }
    return true;
  }

  Future<void> pickGovernmentId() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) governmentIdFile.value = File(xfile.path);
  }

  Future<void> pickCertificate() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) certificateFile.value = File(xfile.path);
  }

  Future<void> pickProfilePhoto() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile != null) profilePhotoFile.value = File(xfile.path);
  }

  // ─────────────────────────────────────────────────────────────────
  // SUBMIT ONBOARDING
  // PATCH /pro/onboarding/   (multipart/form-data)
  // Fields : business_address, service_radius, services (category id)
  // Files  : government_id, professional_certificate, profile_photo
  // Response: { status, onboarding_status, is_complete, message }
  // ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  Future<void> submitOnboarding() async {
    // ── Validation ──────────────────────────────────────────────
    if (businessAddressController.text.trim().isEmpty) {
      _showError('Please enter your business address');
      return;
    }
    if (selectedCategories.isEmpty) {
      _showError('Please select at least one service category');
      return;
    }
    if (governmentIdFile.value == null ||
        certificateFile.value == null ||
        profilePhotoFile.value == null) {
      _showError('Please upload all three documents');
      return;
    }

    isLoading.value = true;
    try {
      // Use the first selected category's id
      // (backend field is "services" = single category id as text)
      final firstCategoryId =
          categoryIdMap[selectedCategories.first]?.toString() ?? '1';

      final response = await _apiClient.multipart(
        ApiEndpoint.providerOnboarding,
        method: 'PATCH',
        fields: {
          'business_address': businessAddressController.text.trim(),
          'service_radius': serviceRadius.value.toInt().toString(),
          'services': firstCategoryId,
        },
        files: {
          'government_id': governmentIdFile.value!,
          'professional_certificate': certificateFile.value!,
          'profile_photo': profilePhotoFile.value!,
        },
      );

      if (response != null) {
        // Save the returned onboarding_status
        final status = response['onboarding_status']?.toString() ?? '';
        if (status.isNotEmpty) {
          await UserInfo.setOnboardingStatus(status);
        }
        print('✅ Onboarding submitted: $response');
      }

      // Always go to Screen 4 (application submitted) after successful POST
      // The PageController in Onboarding widget handles this via onNext()
      // We signal success so the screen can call onNext()
      _onboardingSubmitSuccess.value = true;
    } on HttpException catch (e) {
      _showError(e.message);
    } catch (e) {
      print('❌ Onboarding submit error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Signal for Screen3 to know submission succeeded → call onNext()
  final RxBool _onboardingSubmitSuccess = false.obs;
  bool get onboardingSubmitSuccess => _onboardingSubmitSuccess.value;
  void resetSubmitSuccess() => _onboardingSubmitSuccess.value = false;

  // ─────────────────────────────────────────────────────────────────
  // AFTER ONBOARDING COMPLETE → Go back to SignIn
  // The user must log in again so the app gets the updated
  // onboarding_status from the server.
  // ─────────────────────────────────────────────────────────────────
  Future<void> goToSignInAfterOnboarding() async {
    // Clear tokens so the app treats them as logged-out
    await UserInfo.clearAll();
    Get.offAllNamed(RouteName.signin);
    _showSuccess(
      'Application submitted! Please sign in again to continue.',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SNACKBARS
  // ─────────────────────────────────────────────────────────────────
  void _showError(String message) => Get.snackbar(
    "Error", message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.red.shade700,
    colorText: Colors.white,
    icon: const Icon(Icons.error_outline, color: Colors.white),
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 5),
  );

  void _showSuccess(String message) => Get.snackbar(
    "Success", message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.green.shade700,
    colorText: Colors.white,
    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 4),
  );

  @override
  void onClose() {
    businessAddressController.dispose();
    super.onClose();
  }
}