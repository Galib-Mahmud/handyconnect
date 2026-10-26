import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';
import 'location_tracking_controller.dart'; // adjust path if needed

// ── Timeline enums / model ──────────────────────────────────────────
enum TimelineStatus { completed, active, pending }

class TimelineStep {
  final String label;
  final String? subtitle;
  final TimelineStatus status;
  final String? time;

  const TimelineStep({
    required this.label,
    this.subtitle,
    required this.status,
    this.time,
  });
}

// ── API status order ──────────────────────────────────────────────
const _statusOrder = {
  'PENDING'    : 0,
  'ACCEPTED'   : 1,
  'ON_THE_WAY' : 2,
  'IN_PROGRESS': 3,
  'COMPLETED'  : 4,
  'REVIEWED'   : 5,
  'BILLED'     : 6,
  'CLOSED'     : 7,
};

// ── Controller ─────────────────────────────────────────────────────
class InProgressController extends GetxController {
  final ApiClient _api = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observable state ────────────────────────────────────────────
  final technicianName   = ''.obs;
  final technicianImage  = ''.obs;
  final technicianRating = 0.0.obs;
  final technicianJobs   = 0.obs;
  final currentStatus    = 'PENDING'.obs;

  final steps    = <TimelineStep>[].obs;
  final isLoading = true.obs;
  final errorMsg  = ''.obs;

  // ── Interested providers (shown when PENDING) ──────────────────
  final RxList<Map<String, dynamic>> interestedProviders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingProviders = false.obs;
  final RxBool isHiring           = false.obs;

  // ── Bill & Job Completion state ──────────────────────────────────
  final RxBool isConfirmingBill = false.obs;
  final RxBool isClosingJob     = false.obs;
  final RxBool isCancelling     = false.obs;
  final RxBool billConfirmed    = false.obs;

  // ── Review state ─────────────────────────────────────────────────
  final RxInt    reviewRating       = 0.obs;
  final RxString reviewComment      = ''.obs;
  final RxBool   isSubmittingReview = false.obs;
  final RxBool   hasReviewed        = false.obs;

  // ── Request id ───────────────────────────────────────────────────
  // Set ONCE in onInit():
  //   1) Get.arguments['requestId']  (Recent Request screen theke)
  //   2) UserInfo saved id           (notun request create korar por)
  late final int requestId;

  /// Screen theke shoraasori pass kora id (sobcheye nirbhorjogyo).
  final int? _initialRequestId;

  InProgressController({int? requestId}) : _initialRequestId = requestId;

  String get _myName => UserInfo.getFullNameSync() ?? '';

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    final int? argId = (args is Map && args['requestId'] is int)
        ? args['requestId'] as int
        : null;

    requestId = _initialRequestId ?? argId ?? UserInfo.getRequestIdSync() ?? 0;
    print('🆔 [IN-PROGRESS] requestId=$requestId '
        '(ctor=$_initialRequestId, args=$argId, saved=${UserInfo.getRequestIdSync()})');

    fetchStatus();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => fetchStatus());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    // Clean up the tracking controller tied to this request, if it was created.
    final tag = 'tracking_$requestId';
    if (Get.isRegistered<LocationTrackingController>(tag: tag)) {
      Get.delete<LocationTrackingController>(tag: tag);
    }
    super.onClose();
  }

  // ── Fetch request status ────────────────────────────────────────
  Future<void> fetchStatus() async {
    if (requestId == 0) {
      errorMsg.value = 'No active request found.';
      isLoading.value = false;
      return;
    }

    try {
      if (steps.isEmpty) isLoading.value = true;
      errorMsg.value = '';

      final res = await _api.get(
        '${ApiEndpoint.requests}$requestId/',
        requiresAuth: true,
      ) as Map<String, dynamic>;

      technicianName.value =
          (res['provider_name'] as String?) ?? 'Professional';
      final rawPhoto = (res['provider_photo'] as String?) ?? '';
      technicianImage.value = ApiEndpoint.mediaUrl(rawPhoto);

      final String apiStatus = (res['status'] as String?) ?? 'PENDING';
      currentStatus.value = apiStatus;

      if (apiStatus == 'REVIEWED') hasReviewed.value = true;

      final Map<String, dynamic> tl =
      Map<String, dynamic>.from(res['timeline'] as Map? ?? {});

      steps.assignAll(_buildSteps(apiStatus, tl));

      // Keep the tracking controller's status in sync so it starts/stops
      // WebSocket tracking the instant this poller sees a status change,
      // instead of waiting on its own timers.
      final tag = 'tracking_$requestId';
      if (Get.isRegistered<LocationTrackingController>(tag: tag)) {
        Get.find<LocationTrackingController>(tag: tag)
            .onStatusChanged(apiStatus);
      }

      print('✅ [IN-PROGRESS] status=$apiStatus  provider=${technicianName.value}');

      // Stop polling once closed or cancelled (terminal states)
      if (apiStatus == 'CLOSED' || apiStatus == 'CANCELLED') {
        _pollTimer?.cancel();
      }

      // Fetch interested providers when PENDING
      if (apiStatus == 'PENDING') {
        _fetchInterestedProviders();
      } else {
        interestedProviders.clear();
      }
    } on HttpException catch (e) {
      print('❌ [IN-PROGRESS] HttpException [${e.statusCode}]: ${e.message}');
      errorMsg.value = e.message;
    } catch (e) {
      print('❌ [IN-PROGRESS] unknown: $e');
      errorMsg.value = 'Could not load order status.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Fetch interested providers ──────────────────────────────────
  Future<void> _fetchInterestedProviders() async {
    if (requestId == 0) return;
    try {
      isLoadingProviders.value = true;

      print('📡 [INTERESTED] GET interested-providers for request $requestId');

      final res = await _api.get(
        ApiEndpoint.interestedProviders(requestId),
        requiresAuth: true,
      );

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      final limited = raw.take(3).toList();

      interestedProviders.assignAll(
        limited.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      print('✅ [INTERESTED] ${interestedProviders.length} provider(s)');
    } catch (e) {
      print('❌ [INTERESTED] Error: $e');
    } finally {
      isLoadingProviders.value = false;
    }
  }

  // ── Hire a provider ─────────────────────────────────────────────
  Future<void> hireProvider(int providerId, String providerName) async {
    if (isHiring.value) return;
    if (requestId == 0) {
      Get.snackbar('Error', 'No active request.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isHiring.value = true;

      print('📡 [HIRE] POST hire-provider/$providerId for request $requestId');

      await _api.post(
        ApiEndpoint.hireProvider(requestId),
        body: {'provider_id': providerId},
        requiresAuth: true,
      );

      print('✅ [HIRE] $providerName hired!');

      Get.snackbar('Success', '$providerName has been hired!',
          snackPosition: SnackPosition.BOTTOM);

      await fetchStatus();
    } on HttpException catch (e) {
      print('❌ [HIRE] HttpException: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [HIRE] Error: $e');
      Get.snackbar('Error', 'Could not hire provider.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isHiring.value = false;
    }
  }

  // ── Submit Review ────────────────────────────────────────────────
  // POST /services/requests/{id}/submit-review/
  void setRating(int stars) => reviewRating.value = stars;

  Future<void> submitReview() async {
    if (isSubmittingReview.value) return;

    if (reviewRating.value == 0) {
      Get.snackbar('Rating required', 'Please select a star rating.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (reviewComment.value.trim().length < 10) {
      Get.snackbar('Review too short', 'Please write at least 10 characters.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (requestId == 0) {
      Get.snackbar('Error', 'No active request.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSubmittingReview.value = true;

      print('📡 [REVIEW] POST submit-review/$requestId');
      print('   body: { rating: ${reviewRating.value}, comment: ${reviewComment.value.trim()} }');

      final res = await _api.post(
        ApiEndpoint.submitReview(requestId),
        body: {
          'rating' : reviewRating.value,
          'comment': reviewComment.value.trim(),
        },
        requiresAuth: true,
      );

      print('✅ [REVIEW] $res');

      hasReviewed.value = true;
      currentStatus.value = (res?['status'] as String?) ?? 'REVIEWED';
      await fetchStatus();

      Get.snackbar(
        'Thank you!',
        (res?['message'] as String?) ?? 'Review submitted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on HttpException catch (e) {
      print('❌ [REVIEW] HttpException: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('❌ [REVIEW] Error: $e');
      Get.snackbar('Error', 'Could not submit review.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmittingReview.value = false;
    }
  }

  // ── Build timeline steps ────────────────────────────────────────
  List<TimelineStep> _buildSteps(
      String apiStatus, Map<String, dynamic> tl) {
    final currentOrder = _statusOrder[apiStatus] ?? 0;

    final definitions = [
      ('step_pending'.tr, 'request_received', 0),
      ('step_accepted'.tr, null, 1),
      ('step_on_the_way'.tr, 'on_the_way', 2),
      ('step_in_progress'.tr, 'in_progress', 3),
      ('step_completed'.tr, 'completed', 4),
      ('step_reviewed'.tr, null, 5),
    ];

    return definitions.map((def) {
      final label = def.$1;
      final orderIndex = def.$3;

      TimelineStatus status;
      if (orderIndex < currentOrder) {
        status = TimelineStatus.completed;
      } else if (orderIndex == currentOrder) {
        status = TimelineStatus.active;
      } else {
        status = TimelineStatus.pending;
      }

      String? subtitle;
      if (status == TimelineStatus.active) {
        subtitle = _activeSubtitle(apiStatus);
      }

      String? time;
      final key = def.$2;
      if (key != null && tl[key] != null) {
        final dt = DateTime.tryParse(tl[key].toString());
        if (dt != null) {
          final l = dt.toLocal();
          time = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
        }
      }

      return TimelineStep(
        label: label,
        subtitle: subtitle,
        status: status,
        time: time,
      );
    }).toList();
  }

  String _activeSubtitle(String apiStatus) {
    switch (apiStatus) {
      case 'PENDING':
        return 'sub_waiting_provider'.tr;
      case 'ACCEPTED':
        return 'sub_provider_accepted'.tr;
      case 'ON_THE_WAY':
        return 'sub_provider_on_the_way'.tr;
      case 'IN_PROGRESS':
        return 'sub_work_in_progress'.tr;
      case 'COMPLETED':
        return 'sub_job_completed'.tr;
      case 'REVIEWED':
        return 'sub_thank_you_review'.tr;
      default:
        return '';
    }
  }

  // ── Customer Confirm Bill ───────────────────────────────────────
  // POST /api/services/requests/{id}/customer-confirm-bill/
  Future<void> confirmBill() async {
    if (isConfirmingBill.value) return;
    if (requestId == 0) return;
    try {
      isConfirmingBill.value = true;
      print('📡 [CONFIRM BILL] POST /services/requests/$requestId/customer-confirm-bill/');
      final res = await _api.post(
        ApiEndpoint.customerConfirmBill(requestId),
        requiresAuth: true,
      );
      billConfirmed.value = true;
      Get.snackbar(
        'Bill Confirmed',
        (res?['message'] as String?) ?? 'Bill confirmed successfully.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
      );
      await fetchStatus();
    } on HttpException catch (e) {
      print('❌ [CONFIRM BILL] Error: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
    } catch (e) {
      print('❌ [CONFIRM BILL] Error: $e');
      Get.snackbar('Error', 'Failed to confirm bill.', snackPosition: SnackPosition.TOP);
    } finally {
      isConfirmingBill.value = false;
    }
  }

  // ── Close Job ───────────────────────────────────────────────────
  // POST /api/services/requests/{id}/close-job/
  Future<void> closeJob() async {
    if (isClosingJob.value) return;
    if (requestId == 0) return;
    try {
      isClosingJob.value = true;
      print('📡 [CLOSE JOB] POST /services/requests/$requestId/close-job/');
      final res = await _api.post(
        ApiEndpoint.closeJob(requestId),
        requiresAuth: true,
      );
      Get.snackbar(
        'Job Closed',
        (res?['message'] as String?) ?? 'Job marked as closed.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
      );
      await fetchStatus();
    } on HttpException catch (e) {
      print('❌ [CLOSE JOB] Error: ${e.message}');
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
    } catch (e) {
      print('❌ [CLOSE JOB] Error: $e');
      Get.snackbar('Error', 'Failed to close job.', snackPosition: SnackPosition.TOP);
    } finally {
      isClosingJob.value = false;
    }
  }

  // ── Cancel Order ────────────────────────────────────────────────
  // POST /api/services/requests/{id}/cancel/
  void cancelOrder() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'cancel_order'.tr.isNotEmpty ? 'cancel_order'.tr : 'Cancel Request',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to cancel this request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Request', style: TextStyle(color: Color(0xFF757575))),
          ),
          Obx(() => TextButton(
            onPressed: isCancelling.value ? null : _doCancelOrder,
            child: isCancelling.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935)),
                  )
                : const Text(
                    'Yes, Cancel',
                    style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700),
                  ),
          )),
        ],
      ),
    );
  }

  Future<void> _doCancelOrder() async {
    if (requestId == 0) return;
    try {
      isCancelling.value = true;
      print('📡 [CANCEL] POST /services/requests/$requestId/cancel/');
      await _api.post(
        ApiEndpoint.cancelRequest(requestId),
        requiresAuth: true,
      );
      Get.back(); // close dialog
      currentStatus.value = 'CANCELLED';
      Get.snackbar(
        'Cancelled',
        'Your request has been cancelled.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF8C106),
        colorText: Colors.black,
      );
      await fetchStatus();
    } on HttpException catch (e) {
      Get.back();
      Get.snackbar('Error', e.message, snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to cancel request.', snackPosition: SnackPosition.TOP);
    } finally {
      isCancelling.value = false;
    }
  }

  void openChat() {
    if (Get.isRegistered<ProfessionalChatController>()) {
      Get.delete<ProfessionalChatController>(force: true);
    }

    Get.to(
          () => ProfessionalChatScreen(
        controller: ProfessionalChatController(
          requestId: requestId,
          clientName: technicianName.value,
          jobLabel: 'Job #$requestId',
          clientPhoto: technicianImage.value,
          myFullName: _myName,
        ),
      ),
    );
  }
}