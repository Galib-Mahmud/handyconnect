// lib/features/professional/job_requests/controller/job_requests_controller.dart

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../screen/active_job_screen.dart';
import 'active_job_controller.dart';


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

  // Tracks which request id is currently being responded to (for button spinner)
  final RxInt respondingId = 0.obs;

  final Rx<RequestFilterType> selectedFilter = RequestFilterType.active.obs;

  final RxList<ServiceRequestModel> activeRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> privateRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> emergencyRequests = <ServiceRequestModel>[].obs;
  final RxList<ServiceRequestModel> newRequests = <ServiceRequestModel>[].obs;

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
        queryParameters:
        nextPages[key] != null ? {'page': nextPages[key]} : null,
      );

      final List<dynamic> raw =
      response['results'] is List ? response['results'] as List : [];

      final newList = raw
          .map((e) => ServiceRequestModel.fromJson(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList();

      _updateListByFilter(type, newList);
      nextPages[key] = response['next'] as String?;

      print('✅ [FETCH] Loaded ${newList.length} ${type.name} requests');
    } on HttpException catch (e) {
      print('❌ [FETCH] ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [FETCH] $e');
      Get.snackbar('Error', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore(RequestFilterType type) async {
    final key = _getKeyForFilter(type);
    if (nextPages[key] == null) return;
    await fetchRequestsByFilter(type);
  }

  Future<void> refreshCurrent() async {
    nextPages[_getKeyForFilter(selectedFilter.value)] = null;
    await fetchRequestsByFilter(selectedFilter.value);
  }

  String _getEndpointForFilter(RequestFilterType type) {
    switch (type) {
      case RequestFilterType.active:
        return ApiEndpoint.proActiveRequests;
      case RequestFilterType.private:
        return ApiEndpoint.proPrivateRequests;
      case RequestFilterType.emergency:
        return ApiEndpoint.proEmergencyRequests;
      case RequestFilterType.newRequest:
        return ApiEndpoint.proNewRequests;
    }
  }

  String _getKeyForFilter(RequestFilterType type) {
    switch (type) {
      case RequestFilterType.active:
        return 'active';
      case RequestFilterType.private:
        return 'private';
      case RequestFilterType.emergency:
        return 'emergency';
      case RequestFilterType.newRequest:
        return 'new';
    }
  }

  void _updateListByFilter(
      RequestFilterType type, List<ServiceRequestModel> data) {
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

  bool get hasMore =>
      nextPages[_getKeyForFilter(selectedFilter.value)] != null;

  // ─────────────────────────────────────────────────────────────────
  // RESPOND (Accept / Apply) — both send {"action":"accept"}
  // POST /services/requests/{id}/respond/
  // On success → navigate to ActiveJobScreen with request data.
  // ─────────────────────────────────────────────────────────────────
  Future<void> respondToRequest(int requestId) async {
    if (respondingId.value != 0) return; // prevent double-tap

    final requestData = currentList.firstWhereOrNull((r) => r.id == requestId);
    if (requestData == null) {
      Get.snackbar('Error', 'Request not found.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      respondingId.value = requestId;

      print('📤 [RESPOND] POST respond/ id=$requestId action=accept');

      final res = await _apiClient.post(
        ApiEndpoint.proRequestRespond(requestId),
        body: {'action': 'accept'},
        requiresAuth: true,
      );

      print('✅ [RESPOND] Success: $res');

      _navigateToActiveJob(requestData);
    } on HttpException catch (e) {
      print('❌ [RESPOND] HttpException: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [RESPOND] $e');
      Get.snackbar('Error', 'Could not respond. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      respondingId.value = 0;
    }
  }

  // ── Navigate to Active Job ────────────────────────────────────────
  void _navigateToActiveJob(ServiceRequestModel requestData) {
    final args = <String, dynamic>{
      'jobId': requestData.id,
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

    if (Get.isRegistered<ActiveJobController>()) {
      Get.delete<ActiveJobController>(force: true);
    }
    Get.put(ActiveJobController(), permanent: false);

    Get.to(() => const ActiveJobScreen(), arguments: args);
  }

  // ─────────────────────────────────────────────────────────────────
  // DECLINE — only for private requests.
  // POST /services/requests/{id}/respond/  { "action": "decline" }
  // ─────────────────────────────────────────────────────────────────
  Future<void> declineRequest(int requestId) async {
    if (respondingId.value != 0) return;

    try {
      respondingId.value = requestId;

      print('📤 [DECLINE] POST respond/ id=$requestId action=decline');

      await _apiClient.post(
        ApiEndpoint.proRequestRespond(requestId),
        body: {'action': 'decline'},
        requiresAuth: true,
      );

      // Remove from current list
      currentList.removeWhere((r) => r.id == requestId);

      Get.snackbar('Declined', 'Request declined.',
          snackPosition: SnackPosition.BOTTOM);
    } on HttpException catch (e) {
      print('❌ [DECLINE] HttpException: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [DECLINE] $e');
      // Fallback: still remove locally
      currentList.removeWhere((r) => r.id == requestId);
    } finally {
      respondingId.value = 0;
    }
  }

  // ── View active job (for already-active filter) ───────────────────
  void viewActiveJob(int requestId) {
    final requestData = currentList.firstWhereOrNull((r) => r.id == requestId);
    if (requestData == null) return;
    _navigateToActiveJob(requestData);
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
      case 'COMPLETED':
        return JobStatus.completed;
      case 'IN_PROCESS':
      case 'IN_PROGRESS':
      case 'ON_THE_WAY':
      case 'CONFIRMED':
      case 'ACCEPTED':
        return JobStatus.inProcess;
      default:
        return JobStatus.pending;
    }
  }
}

enum JobStatus { pending, completed, inProcess }