// lib/features/professional/job_requests/controller/job_requests_controller.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';
import 'package:handyConnect/feature/professional/controller/active_job_controller.dart';

// ── Enum for Filter Types ──────────────────────────────────────────
enum RequestFilterType {
  active,
  private,
  emergency,
  newRequest,
}

// ── Model for Service Request ──────────────────────────────────────
class ServiceRequestModel {
  final int id;
  final String customerName;
  final String? customerPhoto;
  final String? phoneNumber;
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
  final double? lat;
  final double? lng;

  const ServiceRequestModel({
    required this.id,
    required this.customerName,
    this.customerPhoto,
    this.phoneNumber,
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
    this.lat,
    this.lng,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] as int,
      customerName: (json['customer_name'] as String?) ?? 'Customer',
      customerPhoto: json['customer_photo'] as String?,
      phoneNumber: json['phone_number'] as String?,
      serviceName: (json['service_name'] as String?) ?? '',
      serviceIcon: (json['service_icon'] as String?) ?? 'water_drop',
      serviceDetails: _asMap(json['service_details']),
      description: (json['description'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      zipCode: (json['zip_code'] as String?) ?? '—',
      aiCost: json['ai_cost'],
      markAsPriority: (json['mark_as_priority'] as bool?) ?? false,
      noCallJustChat: (json['no_call_just_chat'] as bool?) ?? false,
      status: (json['status'] as String?) ?? 'PENDING',
      statusDisplay: (json['status_display'] as String?) ?? 'Pending',
      isSold: (json['is_sold'] as bool?) ?? false,
      isApplied: (json['is_applied'] as bool?) ?? false,
      applicationCount: (json['application_count'] as int?) ?? 0,
      formattedDate: (json['formatted_date'] as String?) ?? '',
      timeline: _asMap(json['timeline']),
      assignedProviderDetails: json['assigned_provider_details'] != null
          ? _asMap(json['assigned_provider_details'])
          : null,
      media: _asList(json['media']),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
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

  // ── Derived Helpers ───────────────────────────────────────────────
  String get displayName {
    if (serviceName.isNotEmpty) return serviceName;
    final n = serviceDetails['name_en'];
    return (n is String && n.isNotEmpty) ? n : 'Service Request';
  }

  String get formattedAiCost => JobRequestsController.formatAiCost(aiCost);
  String get iconAsset => JobRequestsController.assetFromIcon(serviceIcon);
  bool get canApply => !isSold && !isApplied;
  JobStatus get jobStatus => JobRequestsController.statusFromString(status);
}

// ── Controller ─────────────────────────────────────────────────────
class JobRequestsController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observables ───────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Selected filter type
  final Rx<RequestFilterType> selectedFilter = RequestFilterType.active.obs;

  // Request lists for each filter type
  final RxList<ServiceRequestModel> activeRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> privateRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> emergencyRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> newRequests = <ServiceRequestModel>[].obs;

  // Pagination
  final RxMap<String, String?> nextPages = {
    'active': null,
    'private': null,
    'emergency': null,
    'new': null,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequestsByFilter(RequestFilterType.active);
  }

  // ── Change Filter & Fetch Data ────────────────────────────────────
  void changeFilter(RequestFilterType type) {
    if (selectedFilter.value == type) return;
    selectedFilter.value = type;
    fetchRequestsByFilter(type);
  }

  Future<void> fetchRequestsByFilter(RequestFilterType type) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final endpoint = _getEndpointForFilter(type);
      final key = _getKeyForFilter(type);

      print('📋 [FETCH] $type → $endpoint');

      final response = await _apiClient.get(
        endpoint,
        requiresAuth: true,
        queryParameters: nextPages[key] != null ? {'page': nextPages[key]} : null,
      );

      final List<dynamic> raw = response['results'] is List
          ? response['results'] as List
          : [];

      final newList = raw.map((e) => ServiceRequestModel.fromJson(
        Map<String, dynamic>.from(e as Map),
      )).toList();

      // Update appropriate list
      _updateListByFilter(type, newList);

      // Update pagination
      nextPages[key] = response['next'] as String?;

      print('✅ [FETCH] Loaded ${newList.length} ${type.name} requests');
    } on HttpException catch (e) {
      print('❌ [FETCH] ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [FETCH] $e');
      Get.snackbar('Error', 'Something went wrong.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Load More (Pagination) ────────────────────────────────────────
  Future<void> loadMore(RequestFilterType type) async {
    final key = _getKeyForFilter(type);
    if (nextPages[key] == null) return; // No more pages
    await fetchRequestsByFilter(type);
  }

  // ── Refresh Current Filter ────────────────────────────────────────
  Future<void> refreshCurrent() async {
    nextPages[_getKeyForFilter(selectedFilter.value)] = null;
    await fetchRequestsByFilter(selectedFilter.value);
  }

  // ── Helper: Get Endpoint for Filter ───────────────────────────────
  String _getEndpointForFilter(RequestFilterType type) {
    switch (type) {
      case RequestFilterType.active:
        return ApiEndpoint.proActiveRequests; // /services/requests/pro/active/
      case RequestFilterType.private:
        return ApiEndpoint.proPrivateRequests; // /services/requests/pro/private/
      case RequestFilterType.emergency:
        return ApiEndpoint.proEmergencyRequests; // /services/requests/pro/emergency/
      case RequestFilterType.newRequest:
        return ApiEndpoint.proNewRequests; // /services/requests/pro/new/
    }
  }

  String _getKeyForFilter(RequestFilterType type) {
    switch (type) {
      case RequestFilterType.active: return 'active';
      case RequestFilterType.private: return 'private';
      case RequestFilterType.emergency: return 'emergency';
      case RequestFilterType.newRequest: return 'new';
    }
  }

  void _updateListByFilter(RequestFilterType type, List<ServiceRequestModel> data) {
    switch (type) {
      case RequestFilterType.active:
        activeRequests.assignAll(data);
        break;
      case RequestFilterType.private:
        privateRequests.assignAll(data);
        break;
      case RequestFilterType.emergency:
        emergencyRequests.assignAll(data);
        break;
      case RequestFilterType.newRequest:
        newRequests.assignAll(data);
        break;
    }
  }

  // ── Get Current List Based on Selected Filter ─────────────────────
  List<ServiceRequestModel> get currentList {
    switch (selectedFilter.value) {
      case RequestFilterType.active:
        return activeRequests;
      case RequestFilterType.private:
        return privateRequests;
      case RequestFilterType.emergency:
        return emergencyRequests;
      case RequestFilterType.newRequest:
        return newRequests;
    }
  }

  bool get hasMore => nextPages[_getKeyForFilter(selectedFilter.value)] != null;

  // ── Accept Request (Navigate to ActiveJobScreen) ──────────────────
  Future<void> acceptRequest(int requestId) async {
    print('✅ [ACCEPT] requestId: $requestId');

    // Find request in current list
    final requestData = currentList.firstWhere(
          (r) => r.id == requestId,
      orElse: () => throw Exception('Request not found'),
    );

    // Remove from new requests if applicable
    if (selectedFilter.value == RequestFilterType.newRequest) {
      newRequests.removeWhere((r) => r.id == requestId);
    }

    final args = <String, dynamic>{
      'jobId': requestId,
      'customer_name': requestData.customerName,
      'address': requestData.address,
      'customer_photo': requestData.customerPhoto,
      'service_name': requestData.serviceName,
      'service_icon': requestData.serviceIcon,
      'service_details': requestData.serviceDetails,
      'ai_cost': requestData.aiCost,
      'mark_as_priority': requestData.markAsPriority,
      'no_call_just_chat': requestData.noCallJustChat,
      'status': requestData.status,
      'status_display': requestData.statusDisplay,
      'timeline': requestData.timeline,
      'phone_number': requestData.phoneNumber,
      'lat': requestData.lat,
      'lng': requestData.lng,
      'media': requestData.media,
    };

    // Register ActiveJobController
    if (Get.isRegistered<ActiveJobController>()) {
      await Get.delete<ActiveJobController>(force: true);
    }
    Get.put(ActiveJobController(), permanent: false);

    Get.to(() => const ActiveJobScreen(), arguments: args);
  }

  // ── Decline Request ───────────────────────────────────────────────
  void declineRequest(int requestId) {
    print('❌ [DECLINE] Request ID: $requestId');
    currentList.removeWhere((r) => r.id == requestId);
    Get.snackbar('Declined', 'Request declined.', snackPosition: SnackPosition.BOTTOM);
  }

  // ── Apply to Marketplace Request (if needed) ──────────────────────
  Future<void> applyToRequest(int requestId) async {
    try {
      final res = await _apiClient.post(
        ApiEndpoint.proRequestRespond(requestId),
        body: {'action': 'accept'},
        requiresAuth: true,
      );
      print('✅ [APPLY] Response: $res');
      refreshCurrent();

    } catch (e) {
      Get.snackbar('Error', 'Could not apply. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── Static Helpers ────────────────────────────────────────────────
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

  static String assetFromIcon(String icon) {
    const map = {
      'water_drop': 'assets/images/profile/water.png',
      'bolt': 'assets/images/profile/2.png',
      'ac_unit': 'assets/images/profile/3.png',
      'palette': 'assets/images/profile/7.png',
      'local_shipping': 'assets/images/profile/8.png',
      'eco': 'assets/images/profile/12.png',
      'plumber': 'assets/images/profile/water.png',
    };
    return map[icon] ?? 'assets/images/profile/water.png';
  }

  static JobStatus statusFromString(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return JobStatus.completed;
      case 'IN_PROCESS':
      case 'IN_PROGRESS':
      case 'ON_THE_WAY':
      case 'CONFIRMED':
      case 'ACCEPTED':
        return JobStatus.inProcess;
      default: return JobStatus.pending;
    }
  }
}

enum JobStatus { pending, completed, inProcess }