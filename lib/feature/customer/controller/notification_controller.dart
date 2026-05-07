// lib/features/notifications/controller/notification_controller.dart

import 'dart:io';

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';

// ── Model ──────────────────────────────────────────────────────────
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final int? serviceRequest;
  final String time; // created_at_human from API

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.time,
    this.serviceRequest,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id            : json['id'] as int,
      title         : (json['title']   as String?) ?? '',
      message       : (json['message'] as String?) ?? '',
      isRead        : (json['is_read'] as bool?)   ?? false,
      serviceRequest: json['service_request'] as int?,
      time          : (json['created_at_human'] as String?) ?? '',
    );
  }
}

// ── Controller ─────────────────────────────────────────────────────
class NotificationsController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final RxList<NotificationModel> notifications =
      <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Unread badge count — useful for bottom nav badge
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // ── Fetch  GET /services/notifications/ ───────────────────────────
  Future<void> fetchNotifications() async {
    try {
      isLoading.value  = true;
      errorMessage.value = '';
      print('🔔 [NOTIFICATIONS] Fetching...');

      final res = await _apiClient.get(
        ApiEndpoint.notifications, // → /services/notifications/
        requiresAuth: true,
      );

      // Response is a bare List
      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      notifications.assignAll(
        raw.map((e) => NotificationModel.fromJson(
            Map<String, dynamic>.from(e as Map))),
      );

      print('✅ [NOTIFICATIONS] ${notifications.length} loaded');
    } on HttpException catch (e) {
      print('❌ [NOTIFICATIONS] ${e.message}');
      errorMessage.value = e.message;
      Get.snackbar('Error', e.message,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [NOTIFICATIONS] $e');
      errorMessage.value = 'Something went wrong.';
      Get.snackbar('Error', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}