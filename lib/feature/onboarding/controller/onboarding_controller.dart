// lib/feature/onboarding/controller/onboarding_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';

class OnboardingController extends GetxController {
  static OnboardingController get to =>
      Get.put(OnboardingController(), permanent: true);

  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────────────────────────────
  // PROFILE & EXISTING DATA
  // ─────────────────────────────────────────────────────────────────
  final Rx<String?> existingGovernmentIdUrl = Rx<String?>(null);
  final Rx<String?> existingCertificateUrl = Rx<String?>(null);
  final Rx<String?> existingProfilePhotoUrl = Rx<String?>(null);
  final Rx<double?> profileLat = Rx<double?>(null);
  final Rx<double?> profileLng = Rx<double?>(null);
  final RxString currentOnboardingStatus = ''.obs;
  final RxBool isLoadingInitialData = false.obs;

  Future<void> fetchOnboardingData() async {
    try {
      isLoadingInitialData.value = true;
      print('📋 [ONBOARDING] Fetching current onboarding profile...');
      final response = await _apiClient.get(ApiEndpoint.providerOnboarding);
      if (response != null && response is Map<String, dynamic>) {
        print('✅ [ONBOARDING] Current profile: $response');
        if (response['business_address'] != null &&
            response['business_address'].toString().isNotEmpty) {
          businessAddressController.text =
              response['business_address'].toString();
        }
        if (response['government_id'] != null) {
          existingGovernmentIdUrl.value = response['government_id'].toString();
        }
        if (response['professional_certificate'] != null) {
          existingCertificateUrl.value =
              response['professional_certificate'].toString();
        }
        if (response['profile_photo'] != null) {
          existingProfilePhotoUrl.value = response['profile_photo'].toString();
        }
        if (response['service_radius'] != null) {
          serviceRadius.value = (response['service_radius'] as num).toDouble();
        }
        if (response['lat'] != null) {
          profileLat.value = (response['lat'] as num).toDouble();
        }
        if (response['lng'] != null) {
          profileLng.value = (response['lng'] as num).toDouble();
        }
        if (response['services'] is List) {
          final list = response['services'] as List;
          for (var item in list) {
            if (item is int) {
              selectedServiceIds.add(item);
            } else if (item is Map && item['id'] != null) {
              selectedServiceIds.add(item['id'] as int);
            } else if (item is String) {
              final parsed = int.tryParse(item);
              if (parsed != null) selectedServiceIds.add(parsed);
            }
          }
        }
        if (response['onboarding_status'] != null) {
          currentOnboardingStatus.value =
              response['onboarding_status'].toString();
          await UserInfo.setOnboardingStatus(currentOnboardingStatus.value);
        }
      }
    } catch (e) {
      print('⚠️ [ONBOARDING] Could not fetch current onboarding profile: $e');
    } finally {
      isLoadingInitialData.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 3 — Services fetched from API
  // ─────────────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> availableServices =
      <Map<String, dynamic>>[].obs;
  final RxSet<int> selectedServiceIds = <int>{}.obs;
  final RxBool isLoadingServices = false.obs;
  final RxBool isHourly = true.obs;
  final RxDouble serviceRadius = 15.0.obs;
  final businessAddressController = TextEditingController();

  Future<void> fetchServices() async {
    try {
      isLoadingServices.value = true;
      print('📋 [SERVICES] Fetching...');
      final response = await _apiClient.get(ApiEndpoint.servicesList);
      final List<dynamic> list = response is List
          ? response
          : (response is Map && response['results'] is List
              ? response['results'] as List
              : []);
      availableServices.value = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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
    fetchOnboardingData();
    fetchServices();
  }

  // ─────────────────────────────────────────────────────────────────
  // SCREEN 2 — Document Upload
  // ─────────────────────────────────────────────────────────────────
  final Rx<File?> governmentIdFile = Rx<File?>(null);
  final Rx<File?> certificateFile = Rx<File?>(null);
  final Rx<File?> profilePhotoFile = Rx<File?>(null);
  final RxBool isUploadingDocs = false.obs;

  bool get hasGovernmentId =>
      governmentIdFile.value != null ||
      (existingGovernmentIdUrl.value?.isNotEmpty ?? false);

  bool get hasCertificate =>
      certificateFile.value != null ||
      (existingCertificateUrl.value?.isNotEmpty ?? false);

  bool get hasProfilePhoto =>
      profilePhotoFile.value != null ||
      (existingProfilePhotoUrl.value?.isNotEmpty ?? false);

  int get uploadedCount {
    int count = 0;
    if (hasGovernmentId) count++;
    if (hasCertificate) count++;
    if (hasProfilePhoto) count++;
    return count;
  }

  bool validateDocuments() {
    if (!hasGovernmentId || !hasCertificate || !hasProfilePhoto) {
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

  /// Saves any newly picked identity documents to backend during Step 2
  Future<bool> saveIdentityDocuments() async {
    if (!validateDocuments()) return false;

    // If no newly selected files, existing files on backend are sufficient
    if (governmentIdFile.value == null &&
        certificateFile.value == null &&
        profilePhotoFile.value == null) {
      return true;
    }

    isUploadingDocs.value = true;
    try {
      final token = await UserInfo.getAccessToken();
      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final Map<String, dynamic> filesMap = {};
      if (governmentIdFile.value != null) {
        filesMap['government_id'] = await MultipartFile.fromFile(
          governmentIdFile.value!.path,
        );
      }
      if (certificateFile.value != null) {
        filesMap['professional_certificate'] = await MultipartFile.fromFile(
          certificateFile.value!.path,
        );
      }
      if (profilePhotoFile.value != null) {
        filesMap['profile_photo'] = await MultipartFile.fromFile(
          profilePhotoFile.value!.path,
        );
      }

      final formData = FormData.fromMap(filesMap);
      final url = ApiEndpoint.baseUrl + ApiEndpoint.providerOnboarding;
      print('📤 [ONBOARDING] Uploading documents to $url...');
      final response = await dio.patch(url, data: formData);
      print('✅ [ONBOARDING] Documents uploaded: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['government_id'] != null) {
          existingGovernmentIdUrl.value = data['government_id'].toString();
        }
        if (data['professional_certificate'] != null) {
          existingCertificateUrl.value =
              data['professional_certificate'].toString();
        }
        if (data['profile_photo'] != null) {
          existingProfilePhotoUrl.value = data['profile_photo'].toString();
        }
      }
      return true;
    } on DioException catch (e) {
      final msg = _parseDioError(e);
      print('❌ [ONBOARDING] Document upload error: $msg');
      _showError(msg);
      return false;
    } catch (e) {
      print('❌ [ONBOARDING] Document upload error: $e');
      _showError('Failed to upload documents. Please try again.');
      return false;
    } finally {
      isUploadingDocs.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GPS — fast check with fallback
  // ─────────────────────────────────────────────────────────────────
  Future<Position?> _getLocation() async {
    try {
      // 1. Fast check: last known position first
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        print(
            '✅ [GPS] Got last known location: ${lastPos.latitude}, ${lastPos.longitude}');
        return lastPos;
      }

      // 2. Check service & permission
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // 3. Quick getCurrentPosition with 5s timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      print('✅ [GPS] Got current location: ${pos.latitude}, ${pos.longitude}');
      return pos;
    } catch (e) {
      print('⚠️ [GPS] Could not get position: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SUBMIT — PATCH /pro/onboarding/ + POST /pro/onboarding/submit-for-review/
  // ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  Future<void> submitOnboarding() async {
    // ── Validation ────────────────────────────────────────────────
    if (businessAddressController.text.trim().isEmpty) {
      _showError('Please enter your business address.');
      return;
    }
    if (selectedServiceIds.isEmpty) {
      _showError('Please select at least one service category.');
      return;
    }
    if (!validateDocuments()) {
      return;
    }

    isLoading.value = true;
    try {
      // ── Location with fallback ────────────────────────────────
      final pos = await _getLocation();
      final double lat = pos?.latitude ?? (profileLat.value ?? 52.5200);
      final double lng = pos?.longitude ?? (profileLng.value ?? 13.4050);

      print('📤 [ONBOARDING] Submitting...');
      print('   services : ${selectedServiceIds.toList()}');
      print('   lat      : $lat');
      print('   lng      : $lng');
      print('   radius   : ${serviceRadius.value.toInt()} km');

      final String url = ApiEndpoint.baseUrl + ApiEndpoint.providerOnboarding;
      final String? token = await UserInfo.getAccessToken();

      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      // FormData map: JSON-encode services to cleanly match backend serializer
      final Map<String, dynamic> dataMap = {
        'business_address': businessAddressController.text.trim(),
        'service_radius': serviceRadius.value.toInt(),
        'lat': lat,
        'lng': lng,
        'services': jsonEncode(selectedServiceIds.toList()),
      };

      // Attach any files that haven't been uploaded yet
      if (governmentIdFile.value != null) {
        dataMap['government_id'] = await MultipartFile.fromFile(
          governmentIdFile.value!.path,
        );
      }
      if (certificateFile.value != null) {
        dataMap['professional_certificate'] = await MultipartFile.fromFile(
          certificateFile.value!.path,
        );
      }
      if (profilePhotoFile.value != null) {
        dataMap['profile_photo'] = await MultipartFile.fromFile(
          profilePhotoFile.value!.path,
        );
      }

      final formData = FormData.fromMap(dataMap);

      // ── 1. PATCH request (profile & details) ───────────────────
      final dioResponse = await dio.patch(url, data: formData);
      final response = dioResponse.data;
      print('✅ [ONBOARDING] Details saved: $response');

      // ── 2. POST submit-for-review ─────────────────────────────
      final submitUrl = ApiEndpoint.baseUrl + ApiEndpoint.submitForReview;
      print('🌐 [ONBOARDING] Submitting for review: $submitUrl');
      final submitResponse = await dio.post(submitUrl);
      print('✅ [ONBOARDING] Submit for review response: ${submitResponse.data}');

      final String status =
          submitResponse.data?['onboarding_status']?.toString() ??
              response?['onboarding_status']?.toString() ??
              'UNDER_REVIEW';

      await UserInfo.setOnboardingStatus(status);
      currentOnboardingStatus.value = status;
      _onboardingSubmitSuccess.value = true;
    } on DioException catch (e) {
      final msg = _parseDioError(e);
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

  // ─────────────────────────────────────────────────────────────────
  // CHECK ONBOARDING STATUS
  // GET /api/auth/provider/onboarding/status/
  // ─────────────────────────────────────────────────────────────────
  Future<String?> checkOnboardingStatus() async {
    try {
      final response =
          await _apiClient.get(ApiEndpoint.providerOnboardingStatus);
      if (response != null && response is Map<String, dynamic>) {
        final status = response['onboarding_status']?.toString() ??
            response['status']?.toString();
        if (status != null) {
          await UserInfo.setOnboardingStatus(status);
          currentOnboardingStatus.value = status;
          if (status == 'APPROVED') {
            Get.offAllNamed(RouteName.main1);
          }
          return status;
        }
      }
    } catch (e) {
      print('❌ [ONBOARDING_STATUS] Error: $e');
    }
    return null;
  }

  Future<void> goToSignInAfterOnboarding() async {
    await UserInfo.clearAll();
    Get.offAllNamed(RouteName.signin);
    _showSuccess('Application submitted! Please sign in again to continue.');
  }

  // ─────────────────────────────────────────────────────────────────
  // ERROR PARSER
  // ─────────────────────────────────────────────────────────────────
  String _parseDioError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        final List<String> parts = [];
        data.forEach((k, v) {
          final field = k.toString().replaceAll('_', ' ');
          if (v is List) {
            parts.add('$field: ${v.join(", ")}');
          } else if (v is Map) {
            parts.add('$field: ${v.values.join(", ")}');
          } else {
            parts.add('$field: $v');
          }
        });
        if (parts.isNotEmpty) return parts.join('\n');
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.message ?? 'Request failed. Please check your connection.';
  }

  // ─────────────────────────────────────────────────────────────────
  // Snackbars
  // ─────────────────────────────────────────────────────────────────
  void _showError(String message) => Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 5),
      );

  void _showSuccess(String message) => Get.snackbar(
        'Success',
        message,
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
