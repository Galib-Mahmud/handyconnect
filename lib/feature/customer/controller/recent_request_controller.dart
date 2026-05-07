// lib/features/order/controller/recent_request_controller.dart

import 'dart:io';

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';

// ── Model ──────────────────────────────────────────────────────────
class RecentRequestModel {
  final int id;
  final String serviceName;
  final String serviceIcon;
  final String displayText;
  final String status;

  const RecentRequestModel({
    required this.id,
    required this.serviceName,
    required this.serviceIcon,
    required this.displayText,
    required this.status,
  });

  factory RecentRequestModel.fromJson(Map<String, dynamic> json) {
    return RecentRequestModel(
      id          : json['id'] as int,
      serviceName : (json['service_name'] as String?) ?? '',
      serviceIcon : (json['service_icon'] as String?) ?? 'water_drop',
      displayText : (json['display_text'] as String?) ?? '',
      status      : (json['status']       as String?) ?? '',
    );
  }

  // ── Derived UI helpers ─────────────────────────────────────────────

  /// Human-readable label shown in the status badge
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING'    : return 'Pending';
      case 'DIAGNOSING' : return 'Diagnosing';
      case 'ACCEPTED'   : return 'Accepted';
      case 'CONFIRMED'  : return 'Confirmed';
      case 'ON_THE_WAY' : return 'On The Way';
      case 'IN_PROGRESS': return 'In Process';
      case 'COMPLETED'  : return 'Completed';
      case 'CANCELLED'  : return 'Cancelled';
      default           : return status;
    }
  }

  /// Badge background colour per status
  String get badgeBg {
    switch (status.toUpperCase()) {
      case 'COMPLETED'  : return '#E0F2F1';
      case 'IN_PROGRESS':
      case 'ON_THE_WAY' :
      case 'ACCEPTED'   :
      case 'CONFIRMED'  : return '#E3F2FD';
      case 'DIAGNOSING' : return '#FFF8E1';
      case 'CANCELLED'  : return '#FFEBEE';
      default           : return '#F5F5F5'; // PENDING
    }
  }

  /// Badge text colour per status
  String get badgeFg {
    switch (status.toUpperCase()) {
      case 'COMPLETED'  : return '#00897B';
      case 'IN_PROGRESS':
      case 'ON_THE_WAY' :
      case 'ACCEPTED'   :
      case 'CONFIRMED'  : return '#1565C0';
      case 'DIAGNOSING' : return '#F57F17';
      case 'CANCELLED'  : return '#E53935';
      default           : return '#9E9E9E';
    }
  }

  /// Local asset for service icon
  String get iconAsset {
    const map = {
      'water_drop'     : 'assets/images/profile/water.png',
      'bolt'           : 'assets/images/profile/2.png',
      'ac_unit'        : 'assets/images/profile/3.png',
      'palette'        : 'assets/images/profile/7.png',
      'local_shipping' : 'assets/images/profile/8.png',
      'eco'            : 'assets/images/profile/12.png',
    };
    return map[serviceIcon] ?? 'assets/images/profile/water.png';
  }
}

// ── Controller ─────────────────────────────────────────────────────
class RecentRequestController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final RxList<RecentRequestModel> requests = <RecentRequestModel>[].obs;
  final RxBool isLoading                    = false.obs;
  final RxString errorMessage               = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  // ── GET /services/recent-requests/ ────────────────────────────────
  Future<void> fetchRequests() async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';
      print('📋 [RECENT REQUESTS] Fetching...');

      final res = await _apiClient.get(
        ApiEndpoint.recentRequests, // →
        requiresAuth: true,
      );

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      requests.assignAll(
        raw.map((e) => RecentRequestModel.fromJson(
            Map<String, dynamic>.from(e as Map))),
      );

      print('✅ [RECENT REQUESTS] ${requests.length} loaded');
    } on HttpException catch (e) {
      print('❌ [RECENT REQUESTS] ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [RECENT REQUESTS] $e');
      errorMessage.value = 'Something went wrong.';
      Get.snackbar('Error', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}