import 'dart:async';

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';

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

// ── API status order ────────────────────────────────────────────────
const _statusOrder = {
  'PENDING'    : 0,
  'ACCEPTED'   : 1,
  'ON_THE_WAY' : 2,
  'IN_PROGRESS': 3,
  'COMPLETED'  : 4,
  'REVIEWED'   : 5,
};

// ── Controller ──────────────────────────────────────────────────────
class InProgressController extends GetxController {
  final ApiClient _api = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observable state ──────────────────────────────────────────────
  final technicianName   = ''.obs;
  final technicianImage  = ''.obs;
  final technicianRating = 0.0.obs;
  final technicianJobs   = 0.obs;
  final currentStatus    = 'PENDING'.obs;

  final steps    = <TimelineStep>[].obs;
  final isLoading = true.obs;
  final errorMsg  = ''.obs;

  // ── Interested providers (shown when PENDING) ─────────────────────
  final RxList<Map<String, dynamic>> interestedProviders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingProviders = false.obs;
  final RxBool isHiring           = false.obs;

  // ── Review state ──────────────────────────────────────────────────
  final RxInt    reviewRating       = 0.obs;
  final RxString reviewComment      = ''.obs;
  final RxBool   isSubmittingReview = false.obs;
  final RxBool   hasReviewed        = false.obs;

  int    get requestId => UserInfo.getRequestIdSync() ?? 0;
  String get _myName   => UserInfo.getFullNameSync() ?? '';

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    fetchStatus();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => fetchStatus());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  // ── Fetch request status ──────────────────────────────────────────
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
      technicianImage.value = (res['provider_photo'] as String?) ?? '';

      final String apiStatus = (res['status'] as String?) ?? 'PENDING';
      currentStatus.value = apiStatus;

      if (apiStatus == 'REVIEWED') hasReviewed.value = true;

      final Map<String, dynamic> tl =
      Map<String, dynamic>.from(res['timeline'] as Map? ?? {});

      steps.assignAll(_buildSteps(apiStatus, tl));

      print('✅ [IN-PROGRESS] status=$apiStatus  provider=${technicianName.value}');

      // Stop polling once reviewed (terminal state)
      if (apiStatus == 'REVIEWED') {
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

  // ── Fetch interested providers ────────────────────────────────────
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

  // ── Hire a provider ───────────────────────────────────────────────
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

  // ── Submit Review ─────────────────────────────────────────────────
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
      _pollTimer?.cancel();

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

  // ── Build timeline steps ──────────────────────────────────────────
  List<TimelineStep> _buildSteps(
      String apiStatus, Map<String, dynamic> tl) {
    final currentOrder = _statusOrder[apiStatus] ?? 0;

    final definitions = [
      ('Pending', 'request_received', 0),
      ('Job Accepted', null, 1),
      ('On The Way', 'on_the_way', 2),
      ('In Progress', 'in_progress', 3),
      ('Completed', 'completed', 4),
      ('Reviewed', null, 5),
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

      return TimelineStep(
        label: label,
        subtitle: subtitle,
        status: status,
      );
    }).toList();
  }

  String _activeSubtitle(String apiStatus) {
    switch (apiStatus) {
      case 'PENDING':
        return 'Waiting for a provider to accept…';
      case 'ACCEPTED':
        return 'A professional has accepted your request.';
      case 'ON_THE_WAY':
        return "Your professional is on the way!";
      case 'IN_PROGRESS':
        return 'Work is currently in progress.';
      case 'COMPLETED':
        return 'Job completed — please leave a review.';
      case 'REVIEWED':
        return 'Thank you for your review!';
      default:
        return '';
    }
  }

  void cancelOrder() => Get.back();

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