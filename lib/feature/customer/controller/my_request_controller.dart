// lib/features/customer/controller/my_request_controller.dart

import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';

class MyRequestController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final RxBool isLoading = false.obs;
  final RxString selectedTab = 'All'.obs;

  // Full list from API
  final RxList<Map<String, dynamic>> _allRequests =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  // ── Tab → which statuses count ───────────────────────────────────
  static const Map<String, List<String>> _tabStatusMap = {
    'Active'   : ['DRAFT', 'PENDING', 'DIAGNOSING', 'CONFIRMED', 'IN_PROGRESS'],
    'Completed': ['COMPLETED'],
    'Cancelled': ['CANCELLED'],
  };

  // ── Filtered list based on selected tab ──────────────────────────
  List<Map<String, dynamic>> get filteredRequests {
    if (selectedTab.value == 'All') return _allRequests;
    final allowed = _tabStatusMap[selectedTab.value] ?? const [];
    return _allRequests
        .where((r) =>
        allowed.contains((r['status'] ?? '').toString().toUpperCase()))
        .toList();
  }

  void selectTab(String tab) => selectedTab.value = tab;

  // ── Fetch all requests ───────────────────────────────────────────
  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      print('📋 [MY REQUESTS] Fetching...');

      final response = await _apiClient.get(ApiEndpoint.allRequests);

      print('✅ [MY REQUESTS] Response received');

      List<dynamic> raw;
      if (response is List) {
        raw = response;
      } else if (response is Map && response.containsKey('results')) {
        raw = response['results'] as List? ?? [];
      } else {
        raw = [];
      }

      _allRequests.assignAll(
        raw.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      print('📋 Total requests: ${_allRequests.length}');
    } on HttpException catch (e) {
      print('❌ [MY REQUESTS] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [MY REQUESTS] Error: $e');
      Get.snackbar('Error', 'Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Helpers: status → colors ─────────────────────────────────────
  static const Map<String, int> _statusTextColor = {
    'PENDING'    : 0xFFFFA726,
    'DRAFT'      : 0xFF9E9E9E,
    'DIAGNOSING' : 0xFF42A5F5,
    'CONFIRMED'  : 0xFF00897B,
    'IN_PROGRESS': 0xFF42A5F5,
    'COMPLETED'  : 0xFF4CAF50,
    'CANCELLED'  : 0xFFFFFFFF,
  };

  static const Map<String, int> _statusBgColor = {
    'PENDING'    : 0xFFFFF3E0,
    'DRAFT'      : 0xFFF5F5F5,
    'DIAGNOSING' : 0xFFE3F2FD,
    'CONFIRMED'  : 0xFFE0F2F1,
    'IN_PROGRESS': 0xFFE3F2FD,
    'COMPLETED'  : 0xFFE8F5E9,
    'CANCELLED'  : 0xFFF44336,
  };
}