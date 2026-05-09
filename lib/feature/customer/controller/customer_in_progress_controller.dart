import 'dart:async';

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';

// ── Timeline enums / model ────────────────────────────────────────────────────
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

// ── API status order ──────────────────────────────────────────────────────────
// Maps every possible status string to its position in the timeline.
const _statusOrder = {
  'PENDING'    : 0,
  'ACCEPTED'   : 1,
  'ON_THE_WAY' : 2,
  'IN_PROGRESS': 3,
  'COMPLETED'  : 4,
};

// ── Controller ────────────────────────────────────────────────────────────────
class InProgressController extends GetxController {
  final ApiClient _api = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Observable state ──────────────────────────────────────────────
  final technicianName  = ''.obs;
  final technicianImage = ''.obs;
  final technicianRating = 0.0.obs;
  final technicianJobs   = 0.obs;

  final steps       = <TimelineStep>[].obs;
  final isLoading   = true.obs;
  final errorMsg    = ''.obs;

  // raw API fields — kept for chat args
  int    get requestId   => UserInfo.getRequestIdSync() ?? 0;
  String get _myName     => UserInfo.getFullNameSync() ?? '';

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    fetchStatus();
    // Poll every 15 s so the timeline advances without manual refresh
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => fetchStatus());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  // ── Fetch /services/requests/{id}/ ───────────────────────────────
  Future<void> fetchStatus() async {
    if (requestId == 0) {
      errorMsg.value = 'No active request found.';
      isLoading.value = false;
      return;
    }

    try {
      // Only show full-screen spinner on first load
      if (steps.isEmpty) isLoading.value = true;
      errorMsg.value = '';

      final res = await _api.get(
        '${ApiEndpoint.requests}$requestId/',   // → /services/requests/41/
        requiresAuth: true,
      ) as Map<String, dynamic>;

      // ── Provider info ────────────────────────────────────────────
      technicianName.value  = (res['provider_name']  as String?) ?? 'Professional';
      technicianImage.value = (res['provider_photo'] as String?) ?? '';

      // ── Build timeline from status + timeline map ─────────────────
      final String apiStatus          = (res['status'] as String?) ?? 'PENDING';
      final Map<String, dynamic> tl   =
      Map<String, dynamic>.from(res['timeline'] as Map? ?? {});

      steps.assignAll(_buildSteps(apiStatus, tl));

      print('✅ [IN-PROGRESS] status=$apiStatus  provider=${technicianName.value}');
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

  // ── Build timeline steps from API data ───────────────────────────
  List<TimelineStep> _buildSteps(
      String apiStatus,
      Map<String, dynamic> tl,
      ) {
    final currentOrder = _statusOrder[apiStatus] ?? 0;

    // Each entry: (label, timelineKey, orderIndex)
    final definitions = [
      ('Request Received', 'request_received', 0),
      ('Job Accepted',      null,               1),   // no dedicated timestamp
      ('On The Way',        'on_the_way',        2),
      ('In Progress',       'in_progress',       3),
      ('Completed',         'completed',         4),
      ('Payment',           null,                5),
      ('Review',            null,                6),
      ('Closed',            null,                7),
    ];

    return definitions.map((def) {
      final label      = def.$1;
      final tlKey      = def.$2;
      final orderIndex = def.$3;

      // Determine status
      TimelineStatus status;
      if (orderIndex < currentOrder) {
        status = TimelineStatus.completed;
      } else if (orderIndex == currentOrder) {
        status = TimelineStatus.active;
      } else {
        status = TimelineStatus.pending;
      }




      // Subtitle only on active step
      String? subtitle;
      if (status == TimelineStatus.active) {
        subtitle = _activeSubtitle(apiStatus);
      }

      return TimelineStep(
        label   : label,
        subtitle: subtitle,
        status  : status,

      );
    }).toList();
  }

  String _activeSubtitle(String apiStatus) {
    switch (apiStatus) {
      case 'PENDING'    : return 'Waiting for a provider to accept…';
      case 'ACCEPTED'   : return 'A professional has accepted your request.';
      case 'ON_THE_WAY' : return "Your professional is on the way!";
      case 'IN_PROGRESS': return 'Work is currently in progress.';
      case 'COMPLETED'  : return 'Job completed successfully.';
      default           : return '';
    }
  }

  // ── Cancel ───────────────────────────────────────────────────────
  void cancelOrder() => Get.back();

  // ── Open chat ────────────────────────────────────────────────────
  void openChat() {
    // Delete old instance if exists
    if (Get.isRegistered<ProfessionalChatController>()) {
      Get.delete<ProfessionalChatController>(force: true);
    }

    // ✅ Pass real values directly — no Get.arguments needed
    Get.to(
          () => ProfessionalChatScreen(
           controller: ProfessionalChatController(
          requestId  : requestId,
          clientName : technicianName.value,
          jobLabel   : 'Job #$requestId',
          clientPhoto: technicianImage.value,
          myFullName : _myName,
        ),
      ),
    );
  }
}