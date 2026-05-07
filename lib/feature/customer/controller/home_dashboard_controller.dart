// lib/features/home/controller/home_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/endpoint/api_client.dart';
import '../../../../../core/endpoint/api_endpoint.dart';


class HomeController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading   = false.obs;
  final RxString searchQuery = ''.obs;

  // ── Data ──────────────────────────────────────────────────────────
  final Rx<Map<String, dynamic>?>    profile        = Rx(null);
  final RxList<Map<String, dynamic>> recentRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categories     = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allRequests    = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> notifications  = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomepage();
    debounce(
      searchQuery,
          (_) => fetchHomepage(search: searchQuery.value),
      time: const Duration(milliseconds: 500),
    );
  }

  // ── Fetch Homepage ────────────────────────────────────────────────
  Future<void> fetchHomepage({String search = ''}) async {
    try {
      isLoading.value = true;

      final String endpoint = search.trim().isEmpty
          ? ApiEndpoint.customerHomepage
          : '${ApiEndpoint.customerHomepage}?search=${search.trim()}';

      print('🏠 [HOME] Fetching: $endpoint');

      final response = await _apiClient.get(endpoint);

      print('✅ [HOME] Response: $response');

      profile.value        = Map<String, dynamic>.from(response['profile']);
      recentRequests.value = List<Map<String, dynamic>>.from(response['recent_requests']);
      categories.value     = List<Map<String, dynamic>>.from(response['categories']);

      print('👤 Profile    : ${profile.value}');
      print('📋 Recent     : ${recentRequests.length} items');
      print('🗂  Categories : ${categories.length} items');

    } on HttpException catch (e) {
      print('❌ [HOME] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [HOME] Error: $e');
      Get.snackbar('Error', 'Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Fetch All Requests ────────────────────────────────────────────
  Future<void> fetchAllRequests() async {
    try {
      isLoading.value = true;

      print('📋 [ALL REQUESTS] Fetching...');

      final response = await _apiClient.get(ApiEndpoint.allCustomerRequests);

      print('✅ [ALL REQUESTS] Response: $response');

      if (response is List) {
        allRequests.value = List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response.containsKey('results')) {
        allRequests.value = List<Map<String, dynamic>>.from(response['results']);
      } else if (response is Map && response.containsKey('recent_requests')) {
        allRequests.value = List<Map<String, dynamic>>.from(response['recent_requests']);
      } else {
        allRequests.value = [];
      }

      print('📋 Total requests: ${allRequests.length}');

    } on HttpException catch (e) {
      print('❌ [ALL REQUESTS] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [ALL REQUESTS] Error: $e');
      Get.snackbar('Error', 'Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Fetch Notifications ───────────────────────────────────────────
  Future<void> fetchNotifications() async {
    try {
      print('🔔 [NOTIFICATIONS] Fetching...');

      final response = await _apiClient.get(ApiEndpoint.notifications);

      print('✅ [NOTIFICATIONS] Response: $response');

      if (response is List) {
        notifications.value = List<Map<String, dynamic>>.from(response);
      } else if (response is Map && response.containsKey('results')) {
        notifications.value = List<Map<String, dynamic>>.from(response['results']);
      } else {
        notifications.value = [];
      }

      print('🔔 Total notifications: ${notifications.length}');

    } on HttpException catch (e) {
      print('❌ [NOTIFICATIONS] Error: ${e.message}');
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error: $e');
    }
  }

  // ── Helper: icon string → asset path ─────────────────────────────
  static String assetFromString(String icon) {
    const map = {
      'water_drop'     : 'assets/images/profile/water.png',
      'bolt'           : 'assets/images/profile/2.png',
      'ac_unit'        : 'assets/images/profile/3.png',
      'palette'        : 'assets/images/profile/7.png',
      'local_shipping' : 'assets/images/profile/8.png',
      'eco'            : 'assets/images/profile/12.png',
    };
    return map[icon] ?? 'assets/images/profile/water.png';
  }

  // ── Helper: status → text color ──────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING'    : return const Color(0xFFFFA726);
      case 'DIAGNOSING' : return const Color(0xFF42A5F5);
      case 'CONFIRMED'  : return const Color(0xFF00897B);
      case 'COMPLETED'  : return const Color(0xFF4CAF50);
      case 'CANCELLED'  : return const Color(0xFFEF5350);
      default           : return const Color(0xFF9E9E9E);
    }
  }

  // ── Helper: status → background color ────────────────────────────
  static Color statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING'    : return const Color(0xFFFFF3E0);
      case 'DIAGNOSING' : return const Color(0xFFE3F2FD);
      case 'CONFIRMED'  : return const Color(0xFFE0F2F1);
      case 'COMPLETED'  : return const Color(0xFFE8F5E9);
      case 'CANCELLED'  : return const Color(0xFFFFEBEE);
      default           : return const Color(0xFFF5F5F5);
    }
  }
}