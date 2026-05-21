// lib/features/professional/home/views/professional_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/customer/screen/notification_screen.dart';
import 'package:handyConnect/feature/extra/controller/report_issue_controller.dart';
import 'package:handyConnect/feature/professional/controller/professional_home_controller.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';

import '../main_screen_1.dart';



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
                  SizedBox(height: 20.h),

                  // ── Active Jobs ──────────────────────────────────
                  Obx(() => _buildSectionHeader(
                    title: 'Active Jobs',
                    badge: c.activeJobs.length.toString(),
                    showViewAll: c.activeJobs.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1)); // Rebuilds with correct tab
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.activeJobs.isEmpty) {
                      return _buildEmptyCard('No active jobs');
                    }
                    return Column(
                      children: c.activeJobs
                          .map((job) => _buildActiveJobCard(job, context))
                          .toList(),
                    );
                  }),

                  SizedBox(height: 20.h),

                  // ── Emergency Requests ───────────────────────────
                  Obx(() => _buildSectionHeader(
                    title: 'Emergency Request',
                    badge: c.emergencyRequests.length.toString(),
                    showViewAll: c.emergencyRequests.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1)); // Rebuilds with correct tab
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.emergencyRequests.isEmpty) {
                      return _buildEmptyCard('No emergency requests');
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
                    title: 'New Requests',
                    badge: c.newRequests.length.toString(),
                    showViewAll: c.newRequests.isNotEmpty,
                    onViewAll: () {
                      Get.offAll(() => MainScreen1(initialIndex: 1)); // Rebuilds with correct tab
                    },
                  )),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.newRequests.isEmpty) {
                      return _buildEmptyCard('No new requests');
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
                        title: 'Private Requests',
                        badge: c.privateRequests.length.toString(),
                        showViewAll: true,
                        onViewAll: () {},
                      ),
                      SizedBox(height: 10.h),
                      ...c.privateRequests.map((r) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildJobRequestCard(r),
                      )),
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
  // Now reads professionalName, professionalImage from the controller,
  // which are populated by response['profile'] in fetchHomepage()
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
          // Role/category is not in homepage response, so we show
          // email as subtitle (matches the profile JSON structure)
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
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                  c.isOnline.value ? "You're Online" : "You're Offline",
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
            label: 'Emergency',
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
            label: 'Jobs',
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
            label: 'Rating',
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
                Text('View All',
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

  // ─────────────────── Active Job Card ───────────────────────────
  Widget _buildActiveJobCard(Map<String, dynamic> job, BuildContext context) {
    final assetPath  = ProfessionalHomeController.assetFromIcon(job['service_icon'] ?? '');
    final clientName = job['customer_name'] ?? 'Customer';
    final address    = job['address'] ?? '';
    final status     = job['status_display'] ?? job['status'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
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
          GestureDetector(
            onTap: () => Get.to(() => const ActiveJobScreen()),
            child: Container(
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
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const ActiveJobScreen()),
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
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {

                },
                child: Icon(Icons.flag_outlined,
                    color: const Color(0xFF9E9E9E), size: 18.sp),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────── Job Request Card ──────────────────────────
  Widget _buildJobRequestCard(Map<String, dynamic> request) {
    final isSold      = request['is_sold'] ?? false;
    final assetPath   = ProfessionalHomeController.assetFromIcon(request['service_icon'] ?? '');
    final serviceName = request['service_details']?['name_en'] ??
        request['service_name'] ?? 'Service';
    final date        = request['formatted_date'] ?? '';
    // ai_cost is already a formatted String after _normalizeRequest in controller
    final aiCost      = (request['ai_cost'] as String?) ?? '—';
    final address     = request['address'] ?? '';
    final isPriority  = request['mark_as_priority'] ?? false;

    return Stack(
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
                                size: 12.sp, color: const Color(0xFF9E9E9E)),
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
                  // Priority or New badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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
                  // AI Cost — already formatted string e.g. "EUR 160 – 380"
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
                  // Address
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
                                size: 14.sp, color: const Color(0xFF9E9E9E)),
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
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                    Icon(Icons.info_outline, color: Colors.white, size: 16.sp),
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
    );
  }
}