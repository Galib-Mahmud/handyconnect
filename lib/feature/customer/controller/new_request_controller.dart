
// lib/features/home/controllers/request_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:image_picker/image_picker.dart';


import '../../../route/route_name.dart';

class RequestController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker  = ImagePicker();

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading   = false.obs;
  final RxBool canCall     = true.obs;   // "Allow provider to call me"
  final RxBool isEmergency = false.obs;  // "Mark as Emergency"

  // ── Selected Images ───────────────────────────────────────────────
  final RxList<XFile> selectedImages = <XFile>[].obs;

  // ── Created Request ID ────────────────────────────────────────────
  int? createdRequestId;

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
  // Step 1 — POST /services/requests/
  // ─────────────────────────────────────────────────────────────────
  Future<void> submitRequest({
    required int    serviceId,
    required String description,
    required String address,
    required String zipCode,
    required String phoneNumber,
  }) async {
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
    if (phoneNumber.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter your phone number.');
      return;
    }

    try {
      isLoading.value = true;

      // ── 1a. Create the service request ───────────────────────────
      print('📤 [REQUEST] Submitting for service $serviceId...');

      final response = await _apiClient.post(
        ApiEndpoint.createRequest,
        body: {
          'service'          : serviceId,
          'description'      : description.trim(),
          'address'          : address.trim(),
          'zip_code'         : zipCode.trim(),
          'phone_number'     : phoneNumber.trim(),
          'no_call_just_chat': !canCall.value,
          'mark_as_priority' : isEmergency.value,
        },
      );

      print('✅ [REQUEST] Created: $response');
      createdRequestId = response['id'] as int;
      print('🆔 Request ID: $createdRequestId');

      // ── 1b. Upload media files (multipart) ───────────────────────
      if (selectedImages.isNotEmpty) {
        await _uploadMediaFiles(createdRequestId!);
      }

      // ── 1c. Go to analysis screen ────────────────────────────────
      Get.toNamed(
        RouteName.newRequestAnalysis,
        arguments: {'request_id': createdRequestId},
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

  // ─────────────────────────────────────────────────────────────────
  // Step 2 — POST /services/media/upload/  (multipart)
  // Uses ApiClient.multipart() — already in your api_client.dart
  // ─────────────────────────────────────────────────────────────────
  Future<void> _uploadMediaFiles(int requestId) async {
    for (int i = 0; i < selectedImages.length; i++) {
      final XFile image = selectedImages[i];
      print('📸 [MEDIA] Uploading ${i + 1}/${selectedImages.length}: ${image.path}');
      try {
        final response = await _apiClient.multipart(
          ApiEndpoint.uploadMedia,
          method: 'POST',
          fields: {'request': requestId.toString()},
          files : {'file': File(image.path)},
        );
        print('✅ [MEDIA] Uploaded: $response');
      } catch (e) {
        // Non-fatal — log and keep going
        print('⚠️ [MEDIA] Upload failed for image $i: $e');
      }
    }
  }
}