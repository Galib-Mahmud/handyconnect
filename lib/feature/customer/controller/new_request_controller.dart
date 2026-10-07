// lib/features/home/controller/new_request_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../route/route_name.dart';

class RequestController extends GetxController {
  final ApiClient   _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker    = ImagePicker();

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading   = false.obs;
  final RxBool canCall     = true.obs;
  final RxBool isEmergency = false.obs;

  // ── Selected Images ───────────────────────────────────────────────
  final RxList<XFile> selectedImages = <XFile>[].obs;

  // ── Location (mandatory) ──────────────────────────────────────────
  double? _lat;
  double? _lng;

  // ─────────────────────────────────────────────────────────────────
  // Image Picker (Camera & Gallery)
  // ─────────────────────────────────────────────────────────────────
  Future<void> pickImageFromCamera() async {
    final remaining = 5 - selectedImages.length;
    if (remaining <= 0) {
      Get.snackbar('Limit Reached', 'You can upload a maximum of 5 images.');
      return;
    }
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        selectedImages.add(photo);
      }
    } catch (e) {
      print('❌ [CAMERA] Error: $e');
      Get.snackbar('Error', 'Could not access camera or capture photo.');
    }
  }

  Future<void> pickImagesFromGallery() async {
    final remaining = 5 - selectedImages.length;
    if (remaining <= 0) {
      Get.snackbar('Limit Reached', 'You can upload a maximum of 5 images.');
      return;
    }
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      selectedImages.addAll(picked.take(remaining));
    } catch (e) {
      print('❌ [GALLERY] Error: $e');
      Get.snackbar('Error', 'Could not pick images.');
    }
  }

  // Backward compatibility
  Future<void> pickImages() => pickImagesFromGallery();

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GPS — MANDATORY
  // ─────────────────────────────────────────────────────────────────
  Future<bool> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Required',
          'Please enable location services and try again.',
          duration: const Duration(seconds: 4),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Required',
            'Location permission is required to submit a request.',
            duration: const Duration(seconds: 4),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission Denied',
          'Please enable location permission in app settings.',
          duration: const Duration(seconds: 4),
        );
        await Geolocator.openAppSettings();
        return false;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      print('📍 [GPS] Location: $_lat, $_lng');
      return true;
    } catch (e) {
      print('❌ [GPS] Error: $e');
      Get.snackbar(
        'Location Error',
        'Could not get your location. Please try again.',
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 1 — POST /services/media/upload/  (multipart, optional)
  // ─────────────────────────────────────────────────────────────────
  Future<void> _uploadMediaFiles(int requestId) async {
    for (int i = 0; i < selectedImages.length; i++) {
      final XFile image = selectedImages[i];
      print('📸 [MEDIA] Uploading ${i + 1}/${selectedImages.length}');
      try {
        final response = await _apiClient.multipart(
          ApiEndpoint.uploadMedia,
          method: 'POST',
          fields: {'request': requestId.toString()},
          files : {'file': File(image.path)},
        );
        print('✅ [MEDIA] Uploaded: $response');
      } catch (e) {
        print('⚠️ [MEDIA] Upload failed for image $i: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — PATCH /services/requests/{id}/
  // ─────────────────────────────────────────────────────────────────
  Future<void> _finalizeRequest({
    required int    requestId,
    required String description,
    required String address,
    required String zipCode,
    required String phoneNumber,
  }) async {
    print('📤 [FINALIZE] PATCH /services/requests/$requestId/');

    // NOTE: Do NOT send 'status': 'PENDING' here!
    // The request must remain in DRAFT so the backend allows /start-ai/ scanning.
    // Transition to PENDING happens when the user reviews AI diagnosis and confirms.
    final Map<String, dynamic> body = {
      'description'      : description.trim(),
      'address'          : address.trim(),
      'zip_code'         : zipCode.trim(),
      'no_call_just_chat': !canCall.value,
      'mark_as_priority' : isEmergency.value,
      'lat'              : _lat,
      'lng'              : _lng,
    };

    if (phoneNumber.trim().isNotEmpty) {
      body['phone_number'] = phoneNumber.trim();
    }

    print('📦 [FINALIZE] Body: $body');

    final response = await _apiClient.patch(
      '${ApiEndpoint.createRequest}$requestId/',
      body: body,
    );

    print('✅ [FINALIZE] Response: $response');
  }

  // ─────────────────────────────────────────────────────────────────
  // Main submit — requestId already exists (initialized from home)
  // Flow: Location → Media upload → PATCH draft → Navigate to AI
  // ─────────────────────────────────────────────────────────────────
  Future<void> submitRequest({
    required int    requestId,
    required String description,
    required String address,
    required String zipCode,
    required String phoneNumber,
  }) async {
    // ── Validation ────────────────────────────────────────────────
    if (description.trim().isEmpty) {
      Get.snackbar('required'.tr, 'describe_problem_hint'.tr);
      return;
    }
    if (selectedImages.isEmpty) {
      Get.snackbar('photo_required'.tr, 'photo_required_msg'.tr);
      return;
    }
    if (address.trim().isEmpty) {
      Get.snackbar('required'.tr, 'enter_address_hint'.tr);
      return;
    }
    if (zipCode.trim().isEmpty) {
      Get.snackbar('required'.tr, 'zip_code'.tr);
      return;
    }

    try {
      isLoading.value = true;

      // ── Location is MANDATORY ──────────────────────────────────
      final bool locationOk = await _fetchLocation();
      if (!locationOk) return;

      // ── Step 1: Upload media (required for AI analysis) ───────
      await _uploadMediaFiles(requestId);

      // ── Step 2: PATCH details to draft (keeps status DRAFT) ───
      await _finalizeRequest(
        requestId  : requestId,
        description: description,
        address    : address,
        zipCode    : zipCode,
        phoneNumber: phoneNumber,
      );

      // ── Step 3: Navigate to AI analysis ───────────────────────
      Get.toNamed(
        RouteName.newRequestAnalysis,
        arguments: {'request_id': requestId},
      );
    } on HttpException catch (e) {
      print('❌ [REQUEST] HttpException: ${e.message}');
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      print('❌ [REQUEST] Error: $e');
      Get.snackbar('error'.tr, 'something_went_wrong'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}