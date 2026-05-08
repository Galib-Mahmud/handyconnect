import 'package:get/get.dart';

import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';

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
  final technicianName = 'David Cohen'.obs;
  final technicianRating = 4.9.obs;
  final technicianJobs = 124.obs;
  final technicianImage = 'assets/images/profile/profile.png'.obs;

  final steps = <TimelineStep>[
    const TimelineStep(label: 'Request Received', status: TimelineStatus.completed, time: '10:30 AM'),
    const TimelineStep(label: 'Job Accepted', status: TimelineStatus.completed, time: '10:35 AM'),
    const TimelineStep(
      label: 'On The Way',
      subtitle: "We're working on this step right now.",
      status: TimelineStatus.active,
      time: '10:45 AM',
    ),
    const TimelineStep(label: 'In Progress', status: TimelineStatus.pending),
    const TimelineStep(label: 'Completed', status: TimelineStatus.pending),
    const TimelineStep(label: 'Payment', status: TimelineStatus.pending),
    const TimelineStep(label: 'Review', status: TimelineStatus.pending),
    const TimelineStep(label: 'Closed', status: TimelineStatus.pending),
  ].obs;

  void cancelOrder() {
    Get.back();
  }

// openChat() method replace করো:
  void openChat() {
    if (Get.isRegistered<ProfessionalChatController>()) {
      Get.delete<ProfessionalChatController>(force: true);
    }
    Get.put(ProfessionalChatController());

    Get.to(
          () => const ProfessionalChatScreen(),
      arguments: {
        'requestId'  : UserInfo.getRequestIdSync() ?? 0,
        // 'clientName' : technicianName.value,
        'jobLabel'   : 'Job #${UserInfo.getRequestIdSync() ?? 0}',
        // 'clientPhoto': technicianImage.value,
        'myName'     : UserInfo.getFullNameSync() ?? '',
      },
    );
  }
}