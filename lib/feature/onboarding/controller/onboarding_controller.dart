// lib/feature/professional/controllers/onboarding_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingController extends GetxController {
  static OnboardingController get to =>
      Get.put(OnboardingController(), permanent: true);

  final ApiClient   _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker    = ImagePicker();

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 3 — Services fetched from API
  // ─────────────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> availableServices =
      <Map<String, dynamic>>[].obs;
  final RxSet<int>   selectedServiceIds = <int>{}.obs;
  final RxBool       isLoadingServices  = false.obs;
  final RxBool       isHourly           = true.obs;
  final RxDouble     serviceRadius      = 15.0.obs;
  final businessAddressController       = TextEditingController();

  Future<void> fetchServices() async {
    try {
      isLoadingServices.value = true;
      print('📋 [SERVICES] Fetching...');
      final response = await _apiClient.get(ApiEndpoint.servicesList);
      final List<dynamic> list = response is List ? response : [];
      availableServices.value =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      print('✅ [SERVICES] Loaded ${availableServices.length} services');
    } catch (e) {
      print('❌ [SERVICES] Failed: $e');
      _showError('Could not load services. Please try again.');
    } finally {
      isLoadingServices.value = false;
    }
  }

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
  // SCREEN 2 — Document Upload
  // ─────────────────────────────────────────────────────────────────
  final Rx<File?> governmentIdFile = Rx<File?>(null);
  final Rx<File?> certificateFile  = Rx<File?>(null);
  final Rx<File?> profilePhotoFile = Rx<File?>(null);

  int get uploadedCount {
    int count = 0;
    if (governmentIdFile.value != null) count++;
    if (certificateFile.value  != null) count++;
    if (profilePhotoFile.value != null) count++;
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
        source: ImageSource.gallery, imageQuality: 85);
    if (xfile != null) profilePhotoFile.value = File(xfile.path);
  }

  // ─────────────────────────────────────────────────────────────────
  // GPS — request permission + get location
  // ─────────────────────────────────────────────────────────────────
  Future<Position?> _getLocation() async {
    // 1. Check service enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Please enable location services and try again.');
      await Geolocator.openLocationSettings(); // opens device location settings
      return null;
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // shows system dialog
      if (permission == LocationPermission.denied) {
        _showError('Location permission is required to continue.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Please enable location in app settings.');
      await Geolocator.openAppSettings();
      return null;
    }

    // 3. Get position — retry once on timeout
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        print('📍 [GPS] Attempt $attempt...');
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
        print('✅ [GPS] Got location: ${pos.latitude}, ${pos.longitude}');
        return pos;
      } catch (e) {
        print('⚠️ [GPS] Attempt $attempt failed: $e');
        if (attempt == 2) {
          _showError('Could not get location. Check GPS and try again.');
          return null;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────
  // SUBMIT — PATCH /pro/onboarding/  (multipart via dio)
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
      // ── Location ──────────────────────────────────────────────
      final pos = await _getLocation();
      if (pos == null) return;

      print('📤 [ONBOARDING] Submitting...');
      print('   services : ${selectedServiceIds.toList()}');
      print('   lat      : ${pos.latitude}');
      print('   lng      : ${pos.longitude}');
      print('   radius   : ${serviceRadius.value.toInt()} km');

      // ── Build URL (plain string concatenation — no interpolation bug) ──
      final String url =
          ApiEndpoint.baseUrl + ApiEndpoint.providerOnboarding;
      print('🌐 [ONBOARDING] URL: $url');

      // ── Auth token ────────────────────────────────────────────
      final String? token = await UserInfo.getAccessToken();

      // ── Dio instance ──────────────────────────────────────────
      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $token',
      };

      // ── FormData — dio sends List as repeated keys ────────────
      // services: [4, 5]  →  services=4&services=5 (Django reads as list)
      final formData = FormData.fromMap({
        'business_address' : businessAddressController.text.trim(),
        'service_radius'   : serviceRadius.value.toInt(),
        'onboarding_status': 'UNDER_REVIEW',
        'lat'              : pos.latitude.toString(),
        'lng'              : pos.longitude.toString(),
        'services'         : selectedServiceIds.toList(),
      });

      // ── Attach files ──────────────────────────────────────────
      formData.files.addAll([
        MapEntry('government_id',
            await MultipartFile.fromFile(governmentIdFile.value!.path)),
        MapEntry('professional_certificate',
            await MultipartFile.fromFile(certificateFile.value!.path)),
        MapEntry('profile_photo',
            await MultipartFile.fromFile(profilePhotoFile.value!.path)),
      ]);

      // ── PATCH request ─────────────────────────────────────────
      final dioResponse = await dio.patch(url, data: formData);
      final response    = dioResponse.data;

      print('✅ [ONBOARDING] Response: $response');

      if (response != null) {
        final status = response['onboarding_status']?.toString() ?? '';
        if (status.isNotEmpty) {
          await UserInfo.setOnboardingStatus(status);
        }
      }

      _onboardingSubmitSuccess.value = true;

    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Request failed.';
      print('❌ [ONBOARDING] DioException: $msg');
      _showError(msg);
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