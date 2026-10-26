// lib/features/professional/home/views/professional_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';


import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';
import '../../customer/screen/notification_screen.dart';
import '../controller/active_job_controller.dart';
import '../controller/job_request_controller.dart';
import '../controller/professional_home_controller.dart';
import '../main_screen_1.dart';
import 'active_job_screen.dart';

class ProfessionalHomeScreen extends StatelessWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfessionalHomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: SafeArea(
        child: Obx(() {
          if (c.isLoading.value &&
              c.activeJobs.isEmpty &&
              c.newRequests.isEmpty &&
              c.emergencyRequests.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF8C106)),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFF8C106),
            onRefresh: c.fetchHomepage,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(c),
                  SizedBox(height: 12.h),
                  _buildOnlineToggle(c),
                  SizedBox(height: 12.h),
                  _buildStatsRow(c),
                  SizedBox(height: 16.h),

                  // ── Ongoing Active Job Highlight Banner ──────────
                  Obx(() {
                    if (c.activeJobs.isEmpty) return const SizedBox.shrink();
                    return _buildOngoingJobBanner(c.activeJobs.first, context, c);
                  }),

                  // ── Active Jobs ──────────────────────────────────
                  Obx(() => _buildSectionHeader(
                    title: 'active_jobs'.tr,
                    badge: c.activeJobs.length.toString(),
                    showViewAll: c.activeJobs.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1));
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.activeJobs.isEmpty) {
                      return _buildEmptyCard('no_active_jobs'.tr);
                    }
                    return Column(
                      children: c.activeJobs
                          .map((job) => _buildActiveJobCard(job, context, c))
                          .toList(),
                    );
                  }),

                  SizedBox(height: 20.h),

                  // ── Emergency Requests ───────────────────────────
                  Obx(() => _buildSectionHeader(
                    title: 'emergency_requests'.tr,
                    badge: c.emergencyRequests.length.toString(),
                    showViewAll: c.emergencyRequests.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1));
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.emergencyRequests.isEmpty) {
                      return _buildEmptyCard('no_job_requests'.tr);
                    }
                    return Column(
                      children: c.emergencyRequests
                          .map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildJobRequestCard(r),
                      ))
                          .toList(),
                    );
                  }),

                  SizedBox(height: 8.h),

                  // ── New Requests ─────────────────────────────────
                  Obx(() => _buildSectionHeader(
                    title: 'new_requests'.tr,
                    badge: c.newRequests.length.toString(),
                    showViewAll: c.newRequests.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1));
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.newRequests.isEmpty) {
                      return _buildEmptyCard('no_job_requests'.tr);
                    }
                    return Column(
                      children: c.newRequests
                          .map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildJobRequestCard(r),
                      ))
                          .toList(),
                    );
                  }),

                  SizedBox(height: 8.h),

                  // ── Private Requests ─────────────────────────────
                  Obx(() => c.privateRequests.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        title: 'private_requests'.tr,
                        badge: c.privateRequests.length.toString(),
                        showViewAll: true,
                        onViewAll: () {   Get.offAll(() => MainScreen1(initialIndex: 1));},
                      ),
                      SizedBox(height: 10.h),
                      ...c.privateRequests.map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildJobRequestCard(r),
                      )),
                    ],
                  )
                      : const SizedBox.shrink()),

                  // ── Completed Jobs ───────────────────────────────
                  Obx(() => c.completedJobs.isNotEmpty
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12.h),
                      _buildSectionHeader(
                        title: 'completed_jobs'.tr,
                        badge: c.completedJobs.length.toString(),
                        showViewAll: true,
                        onViewAll: () {
                          Get.offAll(() => const MainScreen1(
                                initialIndex: 1,
                                initialRequestFilter: RequestFilterType.completed,
                              ));
                        },
                      ),
                      SizedBox(height: 10.h),
                      ...c.completedJobs
                          .map((job) => _buildCompletedJobCard(job, context, c)),
                    ],
                  )
                      : const SizedBox.shrink()),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────── Open Chat ─────────────────────────────────
  void _openChat(ProfessionalHomeController c) {
    if (c.activeJobs.isEmpty) {
      Get.snackbar(
        'No active chat',
        'You have no active jobs to chat about.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final job = c.activeJobs.first;

    final requestId =
        (job['id'] ?? job['request_id'] ?? job['request']) as int? ?? 0;

    if (requestId == 0) {
      Get.snackbar(
        'Error',
        'Could not open chat for this job.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final myName      = UserInfo.getFullNameSync() ?? '';
    final clientName  = (job['customer_name'] as String?) ?? 'Customer';
    final clientPhoto = (job['customer_photo'] as String?) ?? '';

    if (Get.isRegistered<ProfessionalChatController>()) {
      Get.delete<ProfessionalChatController>(force: true);
    }

    Get.to(
          () => ProfessionalChatScreen(
        controller: ProfessionalChatController(
          requestId  : requestId,
          clientName : clientName,
          jobLabel   : 'Job #$requestId',
          clientPhoto: clientPhoto,
          myFullName : myName,
        ),
      ),
    );
  }

  // ─────────────────── Empty State Card ──────────────────────────
  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
        ),
      ),
    );
  }

  // ─────────────────── Profile Card ──────────────────────────────
  Widget _buildProfileCard(ProfessionalHomeController c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // ── Profile Photo ──────────────────────────────────────
          Obx(() {
            final imageUrl = c.professionalImage.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 52.w,
                height: 52.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(c),
              )
                  : _buildAvatarFallback(c),
            );
          }),
          SizedBox(width: 14.w),

          // ── Name + Email ───────────────────────────────────────
          Expanded(
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.professionalName.value.isNotEmpty
                      ? c.professionalName.value
                      : 'Professional',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  c.professionalEmail.value.isNotEmpty
                      ? c.professionalEmail.value
                      : 'Professional',
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            )),
          ),

          // ── Verified Badge ─────────────────────────────────────
          Obx(() => c.isVerified.value
              ? Container(
            margin: EdgeInsets.only(right: 8.w),
            padding:
            EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.verified,
                    color: const Color(0xFF43A047), size: 12.sp),
                SizedBox(width: 3.w),
                Text('Verified',
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF43A047))),
              ],
            ),
          )
              : const SizedBox.shrink()),

          // ── Chat Icon ──────────────────────────────────────────
          GestureDetector(
            onTap: () => _openChat(c),
            child: Padding(
              padding: EdgeInsets.only(right: 14.w),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF212121), size: 24.sp),
            ),
          ),

          // ── Notification Bell ──────────────────────────────────
          GestureDetector(
            onTap: () => Get.to(() => const NotificationsScreen()),
            child: Stack(
              children: [
                Icon(Icons.notifications,
                    color: const Color(0xFF212121), size: 26.sp),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 9.w,
                    height: 9.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8C106),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(ProfessionalHomeController c) {
    final name = c.professionalName.value;
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8C106),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }

  // ─────────────────── Online Toggle ─────────────────────────────
  Widget _buildOnlineToggle(ProfessionalHomeController c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.isOnline.value ? 'online'.tr : 'offline'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  c.isOnline.value
                      ? 'Receiving new job requests'
                      : 'Not receiving job requests',
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          Switch(
            value: c.isOnline.value,
            onChanged: c.toggleOnline,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF43A047),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFBDBDBD),
          ),
        ],
      )),
    );
  }

  // ─────────────────── Stats Row ─────────────────────────────────
  Widget _buildStatsRow(ProfessionalHomeController c) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded,
                  color: const Color(0xFFEF5350), size: 20.sp),
            ),
            value: '${c.emergencyCount.value}',
            label: 'filter_emergency'.tr,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline,
                  color: const Color(0xFF43A047), size: 20.sp),
            ),
            value: '${c.jobsCount.value}',
            label: 'nav_requests'.tr,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: Icon(Icons.star_border,
                  color: const Color(0xFFF8C106), size: 20.sp),
            ),
            value: c.rating.value.toStringAsFixed(1),
            label: 'rating'.tr,
          ),
        ),
      ],
    ));
  }

  Widget _buildStatCard({
    required Widget iconWidget,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          iconWidget,
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF212121))),
          SizedBox(height: 2.h),
          Text(label,
              style:
              TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  // ─────────────────── Section Header ────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    String? badge,
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212121))),
            if (badge != null && badge != '0') ...[
              SizedBox(width: 8.w),
              Container(
                constraints: BoxConstraints(minWidth: 22.w),
                height: 22.w,
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8C106),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
        if (showViewAll)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('view_all'.tr,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1565C0))),
                SizedBox(width: 2.w),
                Icon(Icons.chevron_right,
                    color: const Color(0xFF1565C0), size: 16.sp),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────── Ongoing Job Banner ─────────────────────────
  Widget _buildOngoingJobBanner(
      Map<String, dynamic> job, BuildContext context, ProfessionalHomeController c) {
    final assetPath =
        ProfessionalHomeController.assetFromIcon(job['service_icon'] ?? '');
    final clientName = job['customer_name'] ?? 'Customer';
    final address = job['address'] ?? '';
    final status = job['status_display'] ?? job['status'] ?? '';
    final int jobId =
        (job['id'] ?? job['request_id'] ?? job['request']) as int? ?? 0;

    void openJob() {
      final args = <String, dynamic>{
        'jobId': jobId,
        'customer_name': clientName,
        'address': address,
        'customer_photo': job['customer_photo'] ?? '',
        'service_name': job['service_name'] ?? '',
        'service_icon': job['service_icon'] ?? '',
        'description': job['description'] ?? '',
        'status': job['status'] ?? 'CONFIRMED',
        'status_display': status,
        'timeline': job['timeline'] ?? {},
      };
      if (Get.isRegistered<ActiveJobController>()) {
        Get.delete<ActiveJobController>(force: true);
      }
      Get.put(ActiveJobController(), permanent: false);
      Get.to(() => const ActiveJobScreen(), arguments: args)
          ?.then((_) => c.fetchHomepage());
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: openJob,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'current_ongoing_job'.tr.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00E676),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8C106).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: const Color(0xFFF8C106), width: 1),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF8C106),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Image.asset(assetPath, fit: BoxFit.contain),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 42.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8C106),
                      foregroundColor: const Color(0xFF212121),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: openJob,
                    icon: Icon(Icons.play_arrow_rounded, size: 20.sp),
                    label: Text(
                      'manage_job_and_status'.tr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Active Job Card ───────────────────────────
  Widget _buildActiveJobCard(
      Map<String, dynamic> job, BuildContext context, ProfessionalHomeController c) {
    final assetPath =
        ProfessionalHomeController.assetFromIcon(job['service_icon'] ?? '');
    final clientName = job['customer_name'] ?? 'Customer';
    final address = job['address'] ?? '';
    final status = job['status_display'] ?? job['status'] ?? '';
    final rawStatus = (job['status'] as String? ?? '').toUpperCase();
    final int jobId =
        (job['id'] ?? job['request_id'] ?? job['request']) as int? ?? 0;

    void openJob() {
      final args = <String, dynamic>{
        'jobId': jobId,
        'customer_name': clientName,
        'address': address,
        'customer_photo': job['customer_photo'] ?? '',
        'service_name': job['service_name'] ?? '',
        'service_icon': job['service_icon'] ?? '',
        'description': job['description'] ?? '',
        'status': job['status'] ?? 'CONFIRMED',
        'status_display': status,
        'timeline': job['timeline'] ?? {},
      };
      if (Get.isRegistered<ActiveJobController>()) {
        Get.delete<ActiveJobController>(force: true);
      }
      Get.put(ActiveJobController(), permanent: false);
      Get.to(() => const ActiveJobScreen(), arguments: args)
          ?.then((_) => c.fetchHomepage());
    }

    Color badgeBg = const Color(0xFFE3F2FD);
    Color badgeTextColor = const Color(0xFF1565C0);
    String nextStepHint = 'tap_to_manage'.tr;
    String actionLabel = 'update_status'.tr;

    if (rawStatus == 'ACCEPTED' || rawStatus == 'CONFIRMED') {
      badgeBg = const Color(0xFFFFF8E1);
      badgeTextColor = const Color(0xFFF57F17);
      nextStepHint = 'Next: Start heading over to customer location';
      actionLabel = 'Start Heading Over';
    } else if (rawStatus == 'ON_THE_WAY') {
      badgeBg = const Color(0xFFE8F5E9);
      badgeTextColor = const Color(0xFF2E7D32);
      nextStepHint = 'Next: Arrive at customer address & start job';
      actionLabel = 'Arrived & Start Job';
    } else if (rawStatus == 'IN_PROGRESS') {
      badgeBg = const Color(0xFFEDE7F6);
      badgeTextColor = const Color(0xFF512DA8);
      nextStepHint = 'Next: Upload invoice & completion photos';
      actionLabel = 'Submit Bill & Complete';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: openJob,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Image.asset(assetPath, fit: BoxFit.contain),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clientName,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212121))),
                          SizedBox(height: 4.h),
                          Text(address,
                              style: TextStyle(
                                  fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14.sp, color: const Color(0xFF757575)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          nextStepHint,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF616161),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  height: 38.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8C106),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: openJob,
                    icon: Icon(Icons.touch_app_outlined, size: 16.sp),
                    label: Text(
                      '${'manage_job'.tr} ($actionLabel)',
                      style: TextStyle(
                          fontSize: 12.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Completed Job Card ─────────────────────────
  Widget _buildCompletedJobCard(
      Map<String, dynamic> job, BuildContext context, ProfessionalHomeController c) {
    final assetPath =
        ProfessionalHomeController.assetFromIcon(job['service_icon'] ?? '');
    final clientName = job['customer_name'] ?? 'Customer';
    final address = job['address'] ?? '';
    final status = job['status_display'] ?? job['status'] ?? 'Completed';
    final int jobId =
        (job['id'] ?? job['request_id'] ?? job['request']) as int? ?? 0;

    void openJob() {
      final args = <String, dynamic>{
        'jobId': jobId,
        'customer_name': clientName,
        'address': address,
        'customer_photo': job['customer_photo'] ?? '',
        'service_name': job['service_name'] ?? '',
        'service_icon': job['service_icon'] ?? '',
        'description': job['description'] ?? '',
        'status': 'COMPLETED',
        'status_display': status,
        'timeline': job['timeline'] ?? {},
      };
      if (Get.isRegistered<ActiveJobController>()) {
        Get.delete<ActiveJobController>(force: true);
      }
      Get.put(ActiveJobController(), permanent: false);
      Get.to(() => const ActiveJobScreen(), arguments: args)
          ?.then((_) => c.fetchHomepage());
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: openJob,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              clientName,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212121)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12.sp,
                                    color: const Color(0xFF2E7D32)),
                                SizedBox(width: 4.w),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        address,
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Job Request Card ──────────────────────────
  Widget _buildJobRequestCard(Map<String, dynamic> request) {
    final isSold = request['is_sold'] ?? false;
    final assetPath =
    ProfessionalHomeController.assetFromIcon(request['service_icon'] ?? '');
    final serviceName = request['service_details']?['name_en'] ??
        request['service_name'] ??
        'Service';
    final date = request['formatted_date'] ?? '';
    final aiCost = (request['ai_cost'] as String?) ?? '—';
    final address = request['address'] ?? '';
    final isPriority = request['mark_as_priority'] ?? false;

    return GestureDetector(
      onTap: () {
        Get.offAll(() => const MainScreen1(initialIndex: 1));
      },
      child: Stack(
        children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isSold ? const Color(0xFFF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: isPriority && !isSold
                ? Border.all(color: const Color(0xFFEF5350).withOpacity(0.4))
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    assetPath,
                    width: 40.w,
                    height: 40.w,
                    fit: BoxFit.contain,
                    colorBlendMode: isSold ? BlendMode.saturation : null,
                    color: isSold ? const Color(0xFFBDBDBD) : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: isSold
                                ? const Color(0xFF9E9E9E)
                                : const Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12.sp,
                                color: const Color(0xFF9E9E9E)),
                            SizedBox(width: 4.w),
                            Text(date,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF9E9E9E))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: isPriority
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      isPriority ? 'Priority' : 'New',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isPriority
                            ? const Color(0xFFEF5350)
                            : const Color(0xFF43A047),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Cost',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF9E9E9E))),
                      SizedBox(height: 4.h),
                      Text(
                        aiCost,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isSold
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFFF8C106),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Address',
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF9E9E9E))),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14.sp,
                                color: const Color(0xFF9E9E9E)),
                            SizedBox(width: 2.w),
                            Flexible(
                              child: Text(
                                address,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF424242)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Lead Already Sold overlay ──────────────────────────
        if (isSold)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF474747),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Lead Already Sold',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }
}