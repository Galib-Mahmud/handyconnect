// lib/features/professional/job_requests/controller/job_requests_controller.dart

import 'dart:io';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';
import 'package:handyConnect/feature/professional/controller/active_job_controller.dart';

// ── Model for all available requests ──────────────────────────────
class ServiceRequestModel {
  final int id;
  final String customerName;
  final String? customerPhoto;
  final String serviceName;
  final String serviceIcon;
  final Map<String, dynamic> serviceDetails;
  final String description;
  final String address;
  final String zipCode;
  final dynamic aiCost;
  final bool markAsPriority;
  final bool noCallJustChat;
  final String status;
  final String statusDisplay;
  final bool isSold;
  final bool isApplied;
  final int applicationCount;
  final String formattedDate;
  final Map<String, dynamic> timeline;
  final Map<String, dynamic>? assignedProviderDetails;
  final List<Map<String, dynamic>> media;

  const ServiceRequestModel({
    required this.id,
    required this.customerName,
    this.customerPhoto,
    required this.serviceName,
    required this.serviceIcon,
    required this.serviceDetails,
    required this.description,
    required this.address,
    required this.zipCode,
    required this.aiCost,
    required this.markAsPriority,
    required this.noCallJustChat,
    required this.status,
    required this.statusDisplay,
    required this.isSold,
    required this.isApplied,
    required this.applicationCount,
    required this.formattedDate,
    required this.timeline,
    this.assignedProviderDetails,
    required this.media,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id                      : json['id'] as int,
      customerName            : (json['customer_name'] as String?) ?? 'Customer',
      customerPhoto           : json['customer_photo'] as String?,
      serviceName             : (json['service_name'] as String?) ?? '',
      serviceIcon             : (json['service_icon'] as String?) ?? 'water_drop',
      serviceDetails          : _asMap(json['service_details']),
      description             : (json['description'] as String?) ?? '',
      address                 : (json['address'] as String?) ?? '',
      zipCode                 : (json['zip_code'] as String?) ?? '—',
      aiCost                  : json['ai_cost'],
      markAsPriority          : (json['mark_as_priority'] as bool?) ?? false,
      noCallJustChat          : (json['no_call_just_chat'] as bool?) ?? false,
      status                  : (json['status'] as String?) ?? 'PENDING',
      statusDisplay           : (json['status_display'] as String?) ?? 'Pending',
      isSold                  : (json['is_sold'] as bool?) ?? false,
      isApplied               : (json['is_applied'] as bool?) ?? false,
      applicationCount        : (json['application_count'] as int?) ?? 0,
      formattedDate           : (json['formatted_date'] as String?) ?? '',
      timeline                : _asMap(json['timeline']),
      assignedProviderDetails : json['assigned_provider_details'] != null
          ? _asMap(json['assigned_provider_details'])
          : null,
      media                   : _asList(json['media']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  static List<Map<String, dynamic>> _asList(dynamic v) {
    if (v == null) return [];
    return List<Map<String, dynamic>>.from(
      (v as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ── Derived helpers ────────────────────────────────────────────────
  String get displayName {
    if (serviceName.isNotEmpty) return serviceName;
    final n = serviceDetails['name_en'];
    return (n is String && n.isNotEmpty) ? n : 'Service Request';
  }

  String get formattedAiCost => JobRequestsController.formatAiCost(aiCost);

  String get iconAsset => JobRequestsController.assetFromIcon(serviceIcon);

  bool get canApply => !isSold && !isApplied;

  JobStatus get jobStatus =>
      JobRequestsController.statusFromString(status);
}

// ── Controller ─────────────────────────────────────────────────────
class JobRequestsController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading                                    = false.obs;
  final RxBool isLoadingAll                                 = false.obs;
  final RxString errorMessage                               = ''.obs;

  // Pro requests (own leads)
  final RxList<Map<String, dynamic>> activeAndCompleted     =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> newLeads               =
      <Map<String, dynamic>>[].obs;

  // All available service requests from the marketplace
  final RxList<ServiceRequestModel> allRequests             =
      <ServiceRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
    fetchAllRequests();
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /services/requests/pro/requests/   — own leads
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchRequests() async {
    try {
      isLoading.value   = true;
      errorMessage.value = '';
      print('📋 [PRO REQUESTS] Fetching own leads...');

      final response = await _apiClient.get(
        ApiEndpoint.proRequests,
        requiresAuth: true,
      );

      activeAndCompleted.value = _parseList(response['active_and_completed']);
      newLeads.value           = _parseList(response['new_leads']);

      print('✅ [PRO REQUESTS] Active/Completed: ${activeAndCompleted.length}'
          ' | New Leads: ${newLeads.length}');
    } on HttpException catch (e) {
      print('❌ [PRO REQUESTS] ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [PRO REQUESTS] $e');
      Get.snackbar('Error', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /services/requests/   — all available marketplace requests
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchAllRequests() async {
    try {
      isLoadingAll.value = true;
      print('🌐 [ALL REQUESTS] Fetching marketplace...');

      final res = await _apiClient.get(
        ApiEndpoint.allRequests,   // → /services/requests/
        requiresAuth: true,
      );

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      allRequests.assignAll(
        raw.map((e) => ServiceRequestModel.fromJson(
            Map<String, dynamic>.from(e as Map))),
      );

      print('✅ [ALL REQUESTS] ${allRequests.length} request(s) loaded');
      for (final r in allRequests) {
        print('   [${r.id}] ${r.displayName}'
            ' | status: ${r.status}'
            ' | sold: ${r.isSold}'
            ' | applied: ${r.isApplied}');
      }
    } on HttpException catch (e) {
      print('❌ [ALL REQUESTS] ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [ALL REQUESTS] $e');
      Get.snackbar('Error', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingAll.value = false;
    }
  }

  // ── Refresh both ──────────────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([fetchRequests(), fetchAllRequests()]);
  }

  // ─────────────────────────────────────────────────────────────────
  // Accept a lead from newLeads → navigate to ActiveJobScreen
  // ─────────────────────────────────────────────────────────────────
  Future<void> acceptRequest(int requestId) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ [ACCEPT] requestId: $requestId');
    print('   newLeads IDs: ${newLeads.map((r) => r['id']).toList()}');

    final requestData = newLeads.firstWhere(
          (r) => r['id'] == requestId,
      orElse: () => {},
    );

    if (requestData.isEmpty) {
      print('❌ [ACCEPT] Lead $requestId not found in newLeads');
      Get.snackbar('Error', 'Could not find lead details — try refreshing.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    print('📦 [ACCEPT] Lead found: ${requestData['customer_name']}');
    newLeads.removeWhere((r) => r['id'] == requestId);

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

    // Register ActiveJobController BEFORE navigating
    if (Get.isRegistered<ActiveJobController>()) {
      print('♻️  [ACCEPT] Removing stale ActiveJobController');
      await Get.delete<ActiveJobController>(force: true);
    }
    Get.put(ActiveJobController(), permanent: false);
    print('✅ [ACCEPT] ActiveJobController registered');
    print('🚀 [ACCEPT] Navigating → ActiveJobScreen');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    Get.to(() => const ActiveJobScreen(), arguments: args);
  }

  // ─────────────────────────────────────────────────────────────────
  // Decline a lead from newLeads
  // ─────────────────────────────────────────────────────────────────
  void declineRequest(int requestId) {
    print('❌ [DECLINE] Request ID: $requestId');
    newLeads.removeWhere((r) => r['id'] == requestId);
    Get.snackbar('Declined', 'Request declined.',
        snackPosition: SnackPosition.BOTTOM);
  }

  // ─────────────────────────────────────────────────────────────────
  // Apply to a marketplace request
  // POST /services/requests/{id}/respond/  body: { "action": "apply" }
  // ─────────────────────────────────────────────────────────────────
  Future<void> applyToRequest(int requestId) async {
    print('📝 [APPLY] requestId: $requestId');
    try {
      final res = await _apiClient.post(
        ApiEndpoint.proRequestRespond(requestId),
        body: {'action': 'apply'},
        requiresAuth: true,
      );
      print('✅ [APPLY] Response: $res');

      // Mark as applied locally
      final idx = allRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        // Refresh list to get updated state
        fetchAllRequests();
      }

      Get.snackbar('Applied!', 'Your application has been submitted.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF43A047),
          colorText: const Color(0xFFFFFFFF));
    } on HttpException catch (e) {
      print('❌ [APPLY] ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [APPLY] $e');
      Get.snackbar('Error', 'Could not apply. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Parse raw list ────────────────────────────────────────────────
  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
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

  int get totalCount => activeAndCompleted.length + newLeads.length;
}

enum JobStatus { pending, completed, inProcess }