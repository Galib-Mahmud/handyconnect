// lib/feature/professional/controllers/onboarding_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';
import 'package:dio/dio.dart';
import 'package:handyConnect/core/local_storage/user_info.dart' show UserInfo;
import 'package:image_picker/image_picker.dart';

import '../screen/location_helper.dart';

class OnboardingController extends GetxController {
  static OnboardingController get to =>
      Get.put(OnboardingController(), permanent: true);

  final ApiClient   _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker    = ImagePicker();

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 3 — Services fetched from API
  // ─────────────────────────────────────────────────────────────────

  // Full list from GET /services/list/
  // Each item: { 'id': 4, 'name_en': 'Plumbing', 'icon': '⚡', 'color': '#F54927', ... }
  final RxList<Map<String, dynamic>> availableServices =
      <Map<String, dynamic>>[].obs;

  // Selected service IDs (real IDs from API, e.g. {4, 5})
  final RxSet<int> selectedServiceIds = <int>{}.obs;

  final RxBool   isLoadingServices = false.obs;
  final RxBool   isHourly          = true.obs;
  final RxDouble serviceRadius     = 15.0.obs;
  final businessAddressController  = TextEditingController();

  // ── Fetch services from API ───────────────────────────────────────
  Future<void> fetchServices() async {
    try {
      isLoadingServices.value = true;
      print('📋 [SERVICES] Fetching from ${ApiEndpoint.servicesList}...');

      final response = await _apiClient.get(ApiEndpoint.servicesList);

      // Response is a List
      final List<dynamic> list = response is List ? response : [];
      availableServices.value = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      print('✅ [SERVICES] Loaded ${availableServices.length} services');
      for (final s in availableServices) {
        print('   → id=${s['id']}  name=${s['name_en']}  icon=${s['icon']}');
      }
    } catch (e) {
      print('❌ [SERVICES] Failed to load: $e');
      _showError('Could not load services. Please try again.');
    } finally {
      isLoadingServices.value = false;
    }
  }

  // Toggle by real service ID
  void toggleService(int id) {
    if (selectedServiceIds.contains(id)) {
      selectedServiceIds.remove(id);
    } else {
      selectedServiceIds.add(id);
    }
  }

  bool isSelected(int id) => selectedServiceIds.contains(id);

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 2 — Document Upload state
  // ─────────────────────────────────────────────────────────────────
  final Rx<File?> governmentIdFile  = Rx<File?>(null);
  final Rx<File?> certificateFile   = Rx<File?>(null);
  final Rx<File?> profilePhotoFile  = Rx<File?>(null);

  int get uploadedCount {
    int count = 0;
    if (governmentIdFile.value  != null) count++;
    if (certificateFile.value   != null) count++;
    if (profilePhotoFile.value  != null) count++;
    return count;
  }

  bool validateDocuments() {
    if (governmentIdFile.value == null ||
        certificateFile.value  == null ||
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
  // SUBMIT — Single PATCH /pro/onboarding/  (multipart/form-data)
  //
  // Multiple services → send each id as a separate 'services' field
  // (multipart allows duplicate keys, Django reads them as a list)
  //
  // Fields : business_address, service_radius, services (repeated),
  //          onboarding_status, lat, lng
  // Files  : government_id, professional_certificate, profile_photo
  // ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  Future<void> submitOnboarding() async {
    // ── Validation ────────────────────────────────────────────────
    if (businessAddressController.text.trim().isEmpty) {
      _showError('Please enter your business address.');
      return;
    }
    if (selectedServiceIds.isEmpty) {
      _showError('Please select at least one service.');
      return;
    }
    if (governmentIdFile.value == null ||
        certificateFile.value  == null ||
        profilePhotoFile.value == null) {
      _showError('Please upload all three documents.');
      return;
    }

    isLoading.value = true;
    try {
      // ── Get device location (mandatory) ───────────────────────
      final pos = await LocationHelper.getLocation();
      if (pos == null) return;

      print('📤 [ONBOARDING] Submitting...');
      print('   services  : ${selectedServiceIds.toList()}');
      print('   lat       : ${pos.latitude}');
      print('   lng       : ${pos.longitude}');
      print('   radius    : ${serviceRadius.value.toInt()} km');

      // ── Build FormData (dio supports repeated keys) ──────────
      // services sent as repeated form fields → Django reads as list
      final token = await UserInfo.getAccessToken();
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'business_address' : businessAddressController.text.trim(),
        'service_radius'   : serviceRadius.value.toInt(),
        'onboarding_status': 'UNDER_REVIEW',
        'lat'              : pos.latitude.toString(),
        'lng'              : pos.longitude.toString(),
        // dio sends List as repeated keys: services=4&services=5
        'services': selectedServiceIds.toList(),
      });

      // Attach files
      formData.files.addAll([
        MapEntry('government_id',
            await MultipartFile.fromFile(governmentIdFile.value!.path)),
        MapEntry('professional_certificate',
            await MultipartFile.fromFile(certificateFile.value!.path)),
        MapEntry('profile_photo',
            await MultipartFile.fromFile(profilePhotoFile.value!.path)),
      ]);

      print('📎 [ONBOARDING] services ids: ${selectedServiceIds.toList()}');

      final dioResponse = await dio.patch(
        '\${ApiEndpoint.baseUrl}\${ApiEndpoint.providerOnboarding}',
        data: formData,
      );
      final response = dioResponse.data;

      print('✅ [ONBOARDING] Response: $response');

      if (response != null) {
        final status = response['onboarding_status']?.toString() ?? '';
        if (status.isNotEmpty) {
          await UserInfo.setOnboardingStatus(status);
        }
      }

      _onboardingSubmitSuccess.value = true;

    } on HttpException catch (e) {
      print('❌ [ONBOARDING] HttpException: ${e.message}');
      _showError(e.message);
    } catch (e) {
      print('❌ [ONBOARDING] Error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Success signal → PageView advances to Screen 4
  // ─────────────────────────────────────────────────────────────────
  final RxBool _onboardingSubmitSuccess = false.obs;
  bool get onboardingSubmitSuccess => _onboardingSubmitSuccess.value;
  void resetSubmitSuccess() => _onboardingSubmitSuccess.value = false;

  Future<void> goToSignInAfterOnboarding() async {
    await UserInfo.clearAll();
    Get.offAllNamed(RouteName.signin);
    _showSuccess('Application submitted! Please sign in again to continue.');
  }

  // ─────────────────────────────────────────────────────────────────
  // Snackbars
  // ─────────────────────────────────────────────────────────────────
  void _showError(String message) => Get.snackbar(
    'Error', message,
    snackPosition   : SnackPosition.TOP,
    backgroundColor : Colors.red.shade700,
    colorText       : Colors.white,
    icon            : const Icon(Icons.error_outline, color: Colors.white),
    margin          : const EdgeInsets.all(12),
    borderRadius    : 10,
    duration        : const Duration(seconds: 5),
  );

  void _showSuccess(String message) => Get.snackbar(
    'Success', message,
    snackPosition   : SnackPosition.TOP,
    backgroundColor : Colors.green.shade700,
    colorText       : Colors.white,
    icon            : const Icon(Icons.check_circle_outline, color: Colors.white),
    margin          : const EdgeInsets.all(12),
    borderRadius    : 10,
    duration        : const Duration(seconds: 4),
  );

  @override
  void onClose() {
    businessAddressController.dispose();
    super.onClose();
  }
}