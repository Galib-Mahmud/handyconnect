// lib/feature/customer/controller/address_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';

class AddressModel {
  final int id;
  final String title;
  final String building;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.title,
    this.building = '',
    required this.streetAddress,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int? ?? 0,
      title: (json['label'] ?? json['title'] ?? json['name'] ?? 'Home').toString(),
      building: (json['building'] ?? json['apartment'] ?? '').toString(),
      streetAddress: (json['address_line'] ?? json['street_address'] ?? json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      zipCode: (json['zip_code'] ?? json['postal_code'] ?? '').toString(),
      country: (json['country'] ?? 'Germany').toString(),
      isDefault: json['is_default'] == true || json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': title,
    'title': title,
    'address_line': streetAddress,
    'street_address': streetAddress,
    'address': streetAddress,
    'building': building,
    'city': city,
    'state': state,
    'zip_code': zipCode,
    'country': country,
    'is_default': isDefault,
  };
}

class AddressController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final RxList<AddressModel> addresses = <AddressModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  // ── GET /api/services/addresses/ ──────────────────────────────────
  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final res = await _apiClient.get(ApiEndpoint.addresses, requiresAuth: true);
      final List<dynamic> list = res is List ? res : (res['results'] as List? ?? []);
      addresses.assignAll(
        list.map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
      print('✅ [ADDRESSES] Loaded ${addresses.length} addresses');
    } catch (e) {
      print('❌ [ADDRESSES] Error fetching: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── POST /api/services/addresses/ ─────────────────────────────────
  Future<bool> addAddress({
    required String title,
    required String building,
    required String streetAddress,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      isSaving.value = true;
      final label = title.trim().isNotEmpty ? title.trim() : 'Home';
      final addressLine = streetAddress.trim().isNotEmpty
          ? streetAddress.trim()
          : (building.trim().isNotEmpty ? building.trim() : 'Address');

      final body = {
        'label': label,
        'title': label,
        'address_line': addressLine,
        'street_address': streetAddress.trim(),
        'address': streetAddress.trim(),
        'building': building.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'zip_code': zipCode.trim(),
        'country': country.trim().isNotEmpty ? country.trim() : 'Germany',
        'is_default': isDefault,
      };

      final res = await _apiClient.post(
        ApiEndpoint.addresses,
        body: body,
        requiresAuth: true,
      );

      if (res != null) {
        final newAddress = AddressModel.fromJson(Map<String, dynamic>.from(res as Map));
        addresses.add(newAddress);
      } else {
        await fetchAddresses();
      }

      Get.snackbar(
        'Success',
        'Address saved successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
      return true;
    } on HttpException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
      return false;
    } catch (e) {
      print('❌ [ADDRESSES] Add error: $e');
      Get.snackbar('Error', 'Failed to save address.', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── PATCH /api/services/addresses/{id}/ ───────────────────────────
  Future<bool> updateAddress({
    required int id,
    required String title,
    required String building,
    required String streetAddress,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    try {
      isSaving.value = true;
      final label = title.trim().isNotEmpty ? title.trim() : 'Home';
      final addressLine = streetAddress.trim().isNotEmpty
          ? streetAddress.trim()
          : (building.trim().isNotEmpty ? building.trim() : 'Address');

      final body = {
        'label': label,
        'title': label,
        'address_line': addressLine,
        'street_address': streetAddress.trim(),
        'address': streetAddress.trim(),
        'building': building.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'zip_code': zipCode.trim(),
        'country': country.trim(),
        'is_default': isDefault,
      };

      await _apiClient.patch(
        ApiEndpoint.addressDetail(id),
        body: body,
        requiresAuth: true,
      );

      await fetchAddresses();

      Get.snackbar(
        'Success',
        'Address updated.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
      return true;
    } on HttpException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update address.', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ── DELETE /api/services/addresses/{id}/ ──────────────────────────
  Future<void> deleteAddress(int id) async {
    try {
      await _apiClient.delete(
        ApiEndpoint.addressDetail(id),
        requiresAuth: true,
      );
      addresses.removeWhere((a) => a.id == id);
      Get.snackbar(
        'Success',
        'Address deleted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
    } on HttpException catch (e) {
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete address.', snackPosition: SnackPosition.TOP);
    }
  }
}
