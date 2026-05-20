// lib/features/home/controllers/request_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:image_picker/image_picker.dart';

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

  // ── Draft Request ID ──────────────────────────────────────────────
  int? _draftRequestId;

  // ─────────────────────────────────────────────────────────────────
  // Image Picker
  // ─────────────────────────────────────────────────────────────────
  Future<void> pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: 5,
      );
      if (picked.isEmpty) return;

      final remaining = 5 - selectedImages.length;
      if (remaining <= 0) {
        Get.snackbar('Limit Reached', 'You can upload a maximum of 5 images.');
        return;
      }
      selectedImages.addAll(picked.take(remaining));
    } catch (e) {
      Get.snackbar('Error', 'Could not pick images.');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GPS — MANDATORY. Returns false if location could not be obtained.
  // ─────────────────────────────────────────────────────────────────
  Future<bool> _fetchLocation() async {
    try {
      // 1. Check if location service is on
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Required',
          'Please enable location services and try again.',
          duration: const Duration(seconds: 4),
        );
        return false;
      }

      // 2. Check / request permission
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

      // 3. Get position
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
  // STEP 1 — POST /services/requests/initialize/
  // Body: { "service": serviceId }   ← real id from categories
  // ─────────────────────────────────────────────────────────────────
  Future<int> _initializeRequest(int serviceId) async {
    print('🚀 [INIT] Initializing with service id: $serviceId');

    final response = await _apiClient.post(
      ApiEndpoint.initializeRequest,   // '/services/requests/initialize/'
      body: {'service': serviceId},
    );

    final int requestId = response['id'] as int;
    print('✅ [INIT] Draft request created. ID: $requestId');
    return requestId;
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — POST /services/media/upload/  (multipart, optional)
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
  // STEP 3 — PATCH /services/requests/{id}/
  // lat & lng are mandatory here — already guaranteed before this call
  // ─────────────────────────────────────────────────────────────────
  Future<void> _finalizeRequest({
    required int    requestId,
    required String description,
    required String address,
    required String zipCode,
    required String phoneNumber,
  }) async {
    print('📤 [FINALIZE] PATCH /services/requests/$requestId/');

    final Map<String, dynamic> body = {
      'description'      : description.trim(),
      'address'          : address.trim(),
      'zip_code'         : zipCode.trim(),
      'no_call_just_chat': !canCall.value,
      'mark_as_priority' : isEmergency.value,
      'status'           : 'PENDING',
      'lat'              : _lat,   // always present — checked before this call
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
  // Main — orchestrates all 3 steps
  // serviceId comes from Get.arguments['serviceId'] via the route,
  // set in home_dashboard_screen when user taps a category card.
  // ─────────────────────────────────────────────────────────────────
  Future<void> submitRequest({
    required int    serviceId,
    required String description,
    required String address,
    required String zipCode,
    required String phoneNumber,
  }) async {
    // ── Validation ────────────────────────────────────────────────
    if (description.trim().isEmpty) {
      Get.snackbar('Required', 'Please describe your problem.');
      return;
    }
    if (address.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter your address.');
      return;
    }
    if (zipCode.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter your zip code.');
      return;
    }

    try {
      isLoading.value = true;

      // ── Location is MANDATORY — abort if not obtained ──────────
      final bool locationOk = await _fetchLocation();
      if (!locationOk) return;

      // ── Step 1: Initialize draft ───────────────────────────────
      _draftRequestId = await _initializeRequest(serviceId);

      // ── Step 2: Upload media (if any) ─────────────────────────
      if (selectedImages.isNotEmpty) {
        await _uploadMediaFiles(_draftRequestId!);
      }

      // ── Step 3: PATCH to PENDING ───────────────────────────────
      await _finalizeRequest(
        requestId  : _draftRequestId!,
        description: description,
        address    : address,
        zipCode    : zipCode,
        phoneNumber: phoneNumber,
      );

      // ── Navigate ───────────────────────────────────────────────
      Get.toNamed(
        RouteName.newRequestAnalysis,
        arguments: {'request_id': _draftRequestId},
      );

    } on HttpException catch (e) {
      print('❌ [REQUEST] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [REQUEST] Error: $e');
      Get.snackbar('Error', 'Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}