// lib/features/professional/job_requests/controller/job_requests_controller.dart

import 'dart:io';

import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';


class JobRequestsController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  final RxList<Map<String, dynamic>> activeAndCompleted =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> newLeads =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  // ── Fetch All Requests ────────────────────────────────────────────
  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      print('📋 [PRO REQUESTS] Fetching...');

      final response = await _apiClient.get(ApiEndpoint.proRequests);

      print('✅ [PRO REQUESTS] Response received');

      activeAndCompleted.value = _parseList(response['active_and_completed']);
      newLeads.value = _parseList(response['new_leads']);

      print('🔧 Active/Completed : ${activeAndCompleted.length}');
      print('🆕 New Leads        : ${newLeads.length}');
    } on HttpException catch (e) {
      print('❌ [PRO REQUESTS] HttpException: ${e.message}');
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [PRO REQUESTS] Error: $e');
      Get.snackbar('Error', 'Something went wrong.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Parse raw list ────────────────────────────────────────────────
  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ── Format ai_cost for display only (used in the card UI) ─────────
  /// API: { "min": 160, "max": 380, "currency": "EUR" }  →  "EUR 160 – 380"
  static String formatAiCost(dynamic aiCost) {
    if (aiCost == null) return '—';
    if (aiCost is String) return aiCost.isNotEmpty ? aiCost : '—';
    if (aiCost is Map) {
      final min = aiCost['min'];
      final max = aiCost['max'];
      final currency = aiCost['currency'] ?? '';
      if (min != null && max != null) return '$currency $min – $max';
      if (min != null) return '$currency $min';
      if (max != null) return '$currency $max';
    }
    return '—';
  }

  // ── Accept Request → navigate to ActiveJobScreen ──────────────────
  Future<void> acceptRequest(int requestId) async {
    try {
      // Find the full request object (un-normalised — keep ai_cost as Map)
      final requestData = newLeads.firstWhere(
            (r) => r['id'] == requestId,
        orElse: () => {},
      );

      if (requestData.isEmpty) {
        Get.snackbar('Error', 'Could not find lead details');
        return;
      }

      // Optimistic remove from list
      newLeads.removeWhere((r) => r['id'] == requestId);

      // Pass the FULL raw request so ActiveJobController can read everything
      Get.to(
            () => const ActiveJobScreen(),
        arguments: {
          'jobId': requestId,
          // ── Flat fields ──────────────────────────────────────────
          'customer_name': requestData['customer_name'],
          'address': requestData['address'],
          'customer_photo': requestData['customer_photo'],
          'service_name': requestData['service_name'],       // may be ""
          'service_icon': requestData['service_icon'],
          // ── Nested service details (for name fallback) ───────────
          'service_details': requestData['service_details'], // Map
          // ── AI cost — pass the full Map so controller can unpack ──
          'ai_cost': requestData['ai_cost'],                 // Map {min, max, currency}
          // ── Priority / chat flags ─────────────────────────────────
          'mark_as_priority': requestData['mark_as_priority'] ?? false,
          'no_call_just_chat': requestData['no_call_just_chat'] ?? false,
          // ── Status ────────────────────────────────────────────────
          'status': 'CONFIRMED',
          'status_display': 'Confirmed',
          // ── Timeline ──────────────────────────────────────────────
          'timeline': requestData['timeline'] ?? {},
        },
      );
    } catch (e) {
      print('❌ [ACCEPT ERROR] $e');
      Get.snackbar('Error', 'Could not open job screen.');
    }
  }

  // ── Decline Request ───────────────────────────────────────────────
  Future<void> declineRequest(int requestId) async {
    try {
      print('❌ [DECLINE] Request ID: $requestId');
      newLeads.removeWhere((r) => r['id'] == requestId);
      Get.snackbar('Declined', 'Request declined.');
    } on HttpException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (e) {
      print('❌ [DECLINE] Error: $e');
    }
  }

  // ── Helper: icon string → asset path ─────────────────────────────
  static String assetFromIcon(String icon) {
    const map = {
      'water_drop': 'assets/images/profile/water.png',
      'bolt': 'assets/images/profile/2.png',
      'ac_unit': 'assets/images/profile/3.png',
      'palette': 'assets/images/profile/7.png',
      'local_shipping': 'assets/images/profile/8.png',
      'eco': 'assets/images/profile/12.png',
    };
    return map[icon] ?? 'assets/images/profile/water.png';
  }

  // ── Helper: status string → JobStatus ────────────────────────────
  static JobStatus statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return JobStatus.completed;
      case 'IN_PROCESS':
      case 'IN_PROGRESS':
      case 'ON_THE_WAY':
      case 'CONFIRMED':
        return JobStatus.inProcess;
      default:
        return JobStatus.pending;
    }
  }

  // ── Total count for badge ─────────────────────────────────────────
  int get totalCount => activeAndCompleted.length + newLeads.length;
}

enum JobStatus { pending, completed, inProcess }