// lib/features/home/views/home_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:handyConnect/feature/customer/screen/recent_request_screen.dart';

import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';
import '../controller/home_dashboard_controller.dart';
import 'customer_in_progress_screen.dart';
import 'notification_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController ctrl = Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isLoading.value && ctrl.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF8C106)),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFFF8C106),
            onRefresh: () => ctrl.fetchHomepage(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _buildHeader(ctrl),
                  SizedBox(height: 20.h),
                  _buildSearchBar(ctrl),
                  SizedBox(height: 24.h),
                  _buildRecentRequestHeader(ctrl),
                  SizedBox(height: 12.h),
                  _buildRecentRequests(ctrl),
                  SizedBox(height: 24.h),
                  _buildServicesGrid(ctrl),
                  SizedBox(height: 90.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────── Open Chat ───────────────────────────────────
  void _openChat() {
    final requestId = UserInfo.getRequestIdSync();

    if (requestId == null || requestId == 0) {
      Get.snackbar(
        'No active chat',
        'You have no active request to chat about.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final myName = UserInfo.getFullNameSync() ?? '';

    final controller = ProfessionalChatController(
      requestId : requestId,
      myFullName: myName,
    );

    Get.to(() => ProfessionalChatScreen(controller: controller));
  }

  // ───────────────── Initialize & Navigate ───────────────────────────
  /// Called when user taps a service card.
  /// POST initialize → save requestId → navigate to form with full response.
  void _initializeAndNavigate(
      HomeController ctrl, Map<String, dynamic> category) async {
    // Show loading overlay
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: const CircularProgressIndicator(
                  color: Color(0xFFF8C106),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Setting up your request…',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black26,
    );

    final result = await ctrl.initializeRequest(category['id']);

    // Dismiss loading dialog
    if (Get.isDialogOpen ?? false) Get.back();

    if (result != null) {
      Get.toNamed(
        RouteName.newRequest,
        arguments: {
          'requestId'     : result['id'],
          'serviceDetails': result,
        },
      );
    }
  }

  // ───────────────────────── Header ──────────────────────────────────
  Widget _buildHeader(HomeController ctrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Obx(() {
            final name = ctrl.profile.value?['full_name'] ?? '';
            return Container(
              width: 50.w,
              height: 50.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF8C106),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
          SizedBox(width: 12.w),
          Expanded(
            child: Obx(() {
              final name = ctrl.profile.value?['full_name'] ?? 'User';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF757575),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                ],
              );
            }),
          ),
          // ── Message icon ──
          GestureDetector(
            onTap: () => _openChat(),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF424242),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          // ── Notification icon ──
          GestureDetector(
            onTap: () {
              ctrl.fetchNotifications();
              Get.to(() => const NotificationsScreen());
            },
            child: Icon(
              Icons.notifications_none_rounded,
              color: const Color(0xFF424242),
              size: 26.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Search Bar ──────────────────────────────────
  Widget _buildSearchBar(HomeController ctrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/profile/3.png',
              width: 20.w,
              height: 20.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                onChanged: (val) => ctrl.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'What do you need help with?',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.white,
                  filled: true,
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF212121),
                ),
              ),
            ),
            Icon(Icons.search, color: const Color(0xFFBDBDBD), size: 22.sp),
          ],
        ),
      ),
    );
  }

  // ───────────────── Recent Request Header ───────────────────────────
  Widget _buildRecentRequestHeader(HomeController ctrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Request',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
          GestureDetector(
            onTap: () {
              ctrl.fetchAllRequests();
              Get.to(() => const RecentRequestScreen());
            },
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Recent Request Cards ────────────────────────────
  Widget _buildRecentRequests(HomeController ctrl) {
    return Obx(() {
      if (ctrl.recentRequests.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Center(
              child: Text(
                'No recent requests',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: ctrl.recentRequests.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < ctrl.recentRequests.length - 1 ? 12.h : 0,
              ),
              child: _buildRequestCard(item),
            );
          }).toList(),
        ),
      );
    });
  }

  // ───────────────────── Services Grid ───────────────────────────────
  Widget _buildServicesGrid(HomeController ctrl) {
    return Obx(() {
      if (ctrl.categories.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            childAspectRatio: 0.95,
          ),
          itemCount: ctrl.categories.length,
          itemBuilder: (context, index) {
            final category = ctrl.categories[index];
            return _buildServiceCard(
              category: category,
              onTap: () => _initializeAndNavigate(ctrl, category),
            );
          },
        ),
      );
    });
  }

  // ───────────────────── Dynamic Icon Widget ─────────────────────────
  Widget _buildIconWidget({
    required String icon,
    String? colorHex,
    required double size,
    bool isCircle = false,
  }) {
    final bool emoji = HomeController.isEmoji(icon);

    if (emoji) {
      Color bgColor = const Color(0xFFE0E0E0);
      if (colorHex != null && colorHex.isNotEmpty) {
        try {
          final hex = colorHex.replaceAll('#', '');
          bgColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.15),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(fontSize: (size * 0.5).sp),
          ),
        ),
      );
    }

    final assetPath = HomeController.assetFromString(icon);
    return Image.asset(
      assetPath,
      width: size.w,
      height: size.w,
      fit: BoxFit.contain,
    );
  }

  // ───────────────────── Request Card ────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> item) {
    final status      = item['status'] ?? 'PENDING';
    final displayText = item['display_text'] ?? '';
    final serviceName = item['service_name']?.toString().isNotEmpty == true
        ? item['service_name']
        : 'Service Request';
    final icon      = item['service_icon'] ?? '';
    final colorHex  = item['service_color'] as String?;

    return GestureDetector(
      onTap: () => Get.to(() => const CustomerInProgressScreen()),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconWidget(
              icon: icon,
              colorHex: colorHex,
              size: 40,
              isCircle: true,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: HomeController.statusBgColor(status),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: HomeController.statusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Service Card ────────────────────────────────
  Widget _buildServiceCard({
    required Map<String, dynamic> category,
    VoidCallback? onTap,
  }) {
    final icon     = category['icon'] ?? '';
    final label    = category['name_en'] ?? '';
    final colorHex = category['color'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconWidget(
              icon: icon,
              colorHex: colorHex,
              size: 48,
              isCircle: false,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212121),
              ),
            ),
          ],
        ),
      ),
    );
  }
}