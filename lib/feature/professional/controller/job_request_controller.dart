// // lib/features/professional/job_requests/controller/job_requests_controller.dart
//
// import 'dart:io';
//
// import 'package:get/get.dart';
// import 'package:handyConnect/core/endpoint/api_client.dart';
// import 'package:handyConnect/core/endpoint/api_endpoint.dart';
// import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';
//
//
// class JobRequestsController extends GetxController {
//   final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
//
//   // ── Observables ───────────────────────────────────────────────────
//   final RxBool isLoading = false.obs;
//
//   final RxList<Map<String, dynamic>> activeAndCompleted =
//       <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> newLeads =
//       <Map<String, dynamic>>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     fetchRequests();
//   }
//
//   // ── Fetch All Requests ────────────────────────────────────────────
//   Future<void> fetchRequests() async {
//     try {
//       isLoading.value = true;
//       print('📋 [PRO REQUESTS] Fetching...');
//
//       final response = await _apiClient.get(ApiEndpoint.proRequests);
//
//       print('✅ [PRO REQUESTS] Response received');
//
//       activeAndCompleted.value = _parseList(response['active_and_completed']);
//       newLeads.value = _parseList(response['new_leads']);
//
//       print('🔧 Active/Completed : ${activeAndCompleted.length}');
//       print('🆕 New Leads        : ${newLeads.length}');
//     } on HttpException catch (e) {
//       print('❌ [PRO REQUESTS] HttpException: ${e.message}');
//       Get.snackbar('Error', e.message);
//     } catch (e) {
//       print('❌ [PRO REQUESTS] Error: $e');
//       Get.snackbar('Error', 'Something went wrong.');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // ── Parse raw list ────────────────────────────────────────────────
//   List<Map<String, dynamic>> _parseList(dynamic raw) {
//     if (raw == null) return [];
//     return List<Map<String, dynamic>>.from(
//       (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
//     );
//   }
//
//   // ── Format ai_cost for display only (used in the card UI) ─────────
//   /// API: { "min": 160, "max": 380, "currency": "EUR" }  →  "EUR 160 – 380"
//   static String formatAiCost(dynamic aiCost) {
//     if (aiCost == null) return '—';
//     if (aiCost is String) return aiCost.isNotEmpty ? aiCost : '—';
//     if (aiCost is Map) {
//       final min = aiCost['min'];
//       final max = aiCost['max'];
//       final currency = aiCost['currency'] ?? '';
//       if (min != null && max != null) return '$currency $min – $max';
//       if (min != null) return '$currency $min';
//       if (max != null) return '$currency $max';
//     }
//     return '—';
//   }
//
//   // ── Accept Request → navigate to ActiveJobScreen ──────────────────
//   Future<void> acceptRequest(int requestId) async {
//     try {
//       // Find the full request object (un-normalised — keep ai_cost as Map)
//       final requestData = newLeads.firstWhere(
//             (r) => r['id'] == requestId,
//         orElse: () => {},
//       );
//
//       if (requestData.isEmpty) {
//         Get.snackbar('Error', 'Could not find lead details');
//         return;
//       }
//
//       // Optimistic remove from list
//       newLeads.removeWhere((r) => r['id'] == requestId);
//
//       // Pass the FULL raw request so ActiveJobController can read everything
//       Get.to(
//             () => const ActiveJobScreen(),
//         arguments: {
//           'jobId': requestId,
//           // ── Flat fields ──────────────────────────────────────────
//           'customer_name': requestData['customer_name'],
//           'address': requestData['address'],
//           'customer_photo': requestData['customer_photo'],
//           'service_name': requestData['service_name'],       // may be ""
//           'service_icon': requestData['service_icon'],
//           // ── Nested service details (for name fallback) ───────────
//           'service_details': requestData['service_details'], // Map
//           // ── AI cost — pass the full Map so controller can unpack ──
//           'ai_cost': requestData['ai_cost'],                 // Map {min, max, currency}
//           // ── Priority / chat flags ─────────────────────────────────
//           'mark_as_priority': requestData['mark_as_priority'] ?? false,
//           'no_call_just_chat': requestData['no_call_just_chat'] ?? false,
//           // ── Status ────────────────────────────────────────────────
//           'status': 'CONFIRMED',
//           'status_display': 'Confirmed',
//           // ── Timeline ──────────────────────────────────────────────
//           'timeline': requestData['timeline'] ?? {},
//         },
//       );
//     } catch (e) {
//       print('❌ [ACCEPT ERROR] $e');
//       Get.snackbar('Error', 'Could not open job screen.');
//     }
//   }
//
//   // ── Decline Request ───────────────────────────────────────────────
//   Future<void> declineRequest(int requestId) async {
//     try {
//       print('❌ [DECLINE] Request ID: $requestId');
//       newLeads.removeWhere((r) => r['id'] == requestId);
//       Get.snackbar('Declined', 'Request declined.');
//     } on HttpException catch (e) {
//       Get.snackbar('Error', e.message);
//     } catch (e) {
//       print('❌ [DECLINE] Error: $e');
//     }
//   }
//
//   // ── Helper: icon string → asset path ─────────────────────────────
//   static String assetFromIcon(String icon) {
//     const map = {
//       'water_drop': 'assets/images/profile/water.png',
//       'bolt': 'assets/images/profile/2.png',
//       'ac_unit': 'assets/images/profile/3.png',
//       'palette': 'assets/images/profile/7.png',
//       'local_shipping': 'assets/images/profile/8.png',
//       'eco': 'assets/images/profile/12.png',
//     };
//     return map[icon] ?? 'assets/images/profile/water.png';
//   }
//
//   // ── Helper: status string → JobStatus ────────────────────────────
//   static JobStatus statusFromString(String status) {
//     switch (status.toUpperCase()) {
//       case 'COMPLETED':
//         return JobStatus.completed;
//       case 'IN_PROCESS':
//       case 'IN_PROGRESS':
//       case 'ON_THE_WAY':
//       case 'CONFIRMED':
//         return JobStatus.inProcess;
//       default:
//         return JobStatus.pending;
//     }
//   }
//
//   // ── Total count for badge ─────────────────────────────────────────
//   int get totalCount => activeAndCompleted.length + newLeads.length;
// }
//
// enum JobStatus { pending, completed, inProcess }



// lib/features/professional/job_requests/controller/job_requests_controller.dart

import 'dart:io';

import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';

// ← adjust this import path to match your project structure
import 'package:handyConnect/feature/professional/controller/active_job_controller.dart';


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
  // GET /services/requests/pro/requests/
  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      print('📋 [PRO REQUESTS] Fetching...');

      final response = await _apiClient.get(
        ApiEndpoint.proRequests,
        requiresAuth: true,
      );

      print('✅ [PRO REQUESTS] Response received');

      activeAndCompleted.value = _parseList(response['active_and_completed']);
      newLeads.value           = _parseList(response['new_leads']);

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

  // ── Format ai_cost for display only ──────────────────────────────
  static String formatAiCost(dynamic aiCost) {
    if (aiCost == null) return '—';
    if (aiCost is String) return aiCost.isNotEmpty ? aiCost : '—';
    if (aiCost is Map) {
      final min      = aiCost['min'];
      final max      = aiCost['max'];
      final currency = aiCost['currency'] ?? '';
      if (min != null && max != null) return '$currency $min – $max';
      if (min != null) return '$currency $min';
      if (max != null) return '$currency $max';
    }
    return '—';
  }

  // ── Accept Request → navigate to ActiveJobScreen ──────────────────
  Future<void> acceptRequest(int requestId) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ [ACCEPT] Tapped — requestId: $requestId');
    print('   newLeads count  : ${newLeads.length}');
    print('   newLeads IDs    : ${newLeads.map((r) => r['id']).toList()}');

    // ── 1. Find the lead ──────────────────────────────────────────
    final requestData = newLeads.firstWhere(
          (r) => r['id'] == requestId,
      orElse: () => {},
    );

    if (requestData.isEmpty) {
      print('❌ [ACCEPT] Lead ID $requestId not found in newLeads');
      Get.snackbar(
        'Error',
        'Could not find lead details — try refreshing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    print('📦 [ACCEPT] Lead found: ${requestData['customer_name']}');

    // ── 2. Optimistic remove from UI ──────────────────────────────
    newLeads.removeWhere((r) => r['id'] == requestId);

    // ── 3. Build arguments ────────────────────────────────────────
    final args = <String, dynamic>{
      'jobId'            : requestId,
      'customer_name'    : requestData['customer_name'],
      'address'          : requestData['address'],
      'customer_photo'   : requestData['customer_photo'],
      'service_name'     : requestData['service_name'],
      'service_icon'     : requestData['service_icon'],
      'service_details'  : requestData['service_details'],
      'ai_cost'          : requestData['ai_cost'],
      'mark_as_priority' : requestData['mark_as_priority'] ?? false,
      'no_call_just_chat': requestData['no_call_just_chat'] ?? false,
      'status'           : 'PENDING',
      'status_display'   : 'Pending',
      'timeline'         : requestData['timeline'] ?? {},
    };

    print('🗺️  [ACCEPT] Args ready — jobId: $requestId');

    // ── 4. Register ActiveJobController BEFORE navigating ─────────
    //
    // CRITICAL: ActiveJobScreen calls Get.find<ActiveJobController>()
    // during build. If the controller isn't registered yet the screen
    // throws "not found" and shows the "Could not find lead" error.
    // We must Get.put() BEFORE Get.to().
    //
    if (Get.isRegistered<ActiveJobController>()) {
      print('♻️  [ACCEPT] Removing stale ActiveJobController');
      await Get.delete<ActiveJobController>(force: true);
    }
    Get.put(ActiveJobController(), permanent: false);
    print('✅ [ACCEPT] ActiveJobController registered');

    // ── 5. Navigate ───────────────────────────────────────────────
    print('🚀 [ACCEPT] Navigating → ActiveJobScreen');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    Get.to(
          () => const ActiveJobScreen(),
      arguments: args,
    );
  }

  // ── Decline Request ───────────────────────────────────────────────
  void declineRequest(int requestId) {
    print('❌ [DECLINE] Request ID: $requestId');
    newLeads.removeWhere((r) => r['id'] == requestId);
    Get.snackbar('Declined', 'Request declined.',
        snackPosition: SnackPosition.BOTTOM);
  }

  // ── Helper: icon string → asset path ─────────────────────────────
  static String assetFromIcon(String icon) {
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