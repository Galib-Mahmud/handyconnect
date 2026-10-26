// lib/features/notifications/controller/notification_controller.dart

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

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    bool? isRead,
    int? serviceRequest,
    String? time,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      serviceRequest: serviceRequest ?? this.serviceRequest,
      time: time ?? this.time,
    );
  }

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
  final RxBool isMarkingRead = false.obs;

  // Unread badge count — useful for bottom nav badge
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // ── Fetch  GET /api/services/notifications/ ────────────────────────
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔔 [NOTIFICATIONS] Fetching...');

      final res = await _apiClient.get(
        ApiEndpoint.notifications,
        requiresAuth: true,
      );

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

  // ── POST /api/services/notifications/mark-all-read/ ───────────────
  Future<void> markAllAsRead() async {
    try {
      isMarkingRead.value = true;
      await _apiClient.post(
        ApiEndpoint.notificationsMarkAllRead,
        requiresAuth: true,
      );
      notifications.assignAll(
        notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
      print('✅ [NOTIFICATIONS] All marked as read');
    } catch (e) {
      print('❌ [NOTIFICATIONS] markAllAsRead error: $e');
    } finally {
      isMarkingRead.value = false;
    }
  }

  // ── POST /api/services/notifications/{id}/mark-read/ ──────────────
  Future<void> markAsRead(int id) async {
    try {
      // Optimistically mark as read in local list
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !notifications[index].isRead) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _apiClient.post(
          ApiEndpoint.notificationMarkRead(id),
          requiresAuth: true,
        );
        print('✅ [NOTIFICATIONS] Notification $id marked as read');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] markAsRead error: $e');
    }
  }
}