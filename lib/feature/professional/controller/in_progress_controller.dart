// lib/feature/professional/in_progress/controller/customer_in_progress_controller.dart

import 'package:get/get.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';

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

class InProgressController extends GetxController {
  // Read from Get.arguments (passed by ActiveJobController or JobRequestsController)
  final RxString technicianName   = ''.obs;
  final RxDouble technicianRating = 0.0.obs;
  final RxInt    technicianJobs   = 0.obs;
  final RxString technicianImage  = ''.obs;

  final RxList<TimelineStep> steps = <TimelineStep>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    // Provider info — comes from ActiveJobController args
    technicianName.value   = args['customer_name']  ?? 'Customer';
    technicianImage.value  = args['customer_photo'] ?? '';
    // Rating/jobs not in API yet — defaults
    technicianRating.value = 0.0;
    technicianJobs.value   = 0;

    // Build timeline from the timeline map in args
    final tl = (args['timeline'] as Map<String, dynamic>?) ?? {};
    _buildTimeline(args['status'] ?? 'CONFIRMED', tl);
  }

  void _buildTimeline(String statusCode, Map<String, dynamic> tl) {
    String? _fmt(dynamic v) {
      if (v == null) return null;
      final dt = DateTime.tryParse(v.toString());
      if (dt == null) return null;
      final l = dt.toLocal();
      return '${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
    }

    TimelineStatus _s(String step) {
      const order = ['CONFIRMED', 'ON_THE_WAY', 'IN_PROGRESS', 'COMPLETED'];
      final cur  = order.indexOf(statusCode == 'PENDING' ? 'CONFIRMED' : statusCode);
      final sIdx = order.indexOf(step);
      if (sIdx < cur)  return TimelineStatus.completed;
      if (sIdx == cur) return TimelineStatus.active;
      return TimelineStatus.pending;
    }

    steps.assignAll([
      TimelineStep(
        label: 'Request Received',
        status: TimelineStatus.completed,
        time: _fmt(tl['request_received']),
      ),
      TimelineStep(
        label: 'Job Accepted',
        status: TimelineStatus.completed,
      ),
      TimelineStep(
        label: 'On The Way',
        subtitle: statusCode == 'ON_THE_WAY' ? "Currently on the way to you." : null,
        status: _s('ON_THE_WAY'),
        time: _fmt(tl['on_the_way']),
      ),
      TimelineStep(
        label: 'In Progress',
        status: _s('IN_PROGRESS'),
        time: _fmt(tl['in_progress']),
      ),
      TimelineStep(label: 'Completed', status: _s('COMPLETED'), time: _fmt(tl['completed'])),
      TimelineStep(label: 'Payment',   status: TimelineStatus.pending),
      TimelineStep(label: 'Review',    status: TimelineStatus.pending),
      TimelineStep(label: 'Closed',    status: TimelineStatus.pending),
    ]);
  }

  void cancelOrder() => Get.back();

  // ── Open Chat ─────────────────────────────────────────────────────
  // requestId saved to UserInfo when job was accepted
  void openChat() {
    final requestId = UserInfo.getRequestIdSync() ?? 0;
    final myName    = UserInfo.getFullNameSync() ?? '';

    Get.toNamed(
      RouteName.chat,
      arguments: {
        'requestId'  : requestId,
        'clientName' : technicianName.value,
        'jobLabel'   : 'Job #$requestId',
        'clientPhoto': technicianImage.value,
        'myName'     : myName,
      },
    );
  }
}