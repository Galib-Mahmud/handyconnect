// lib/features/home/views/home_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:handyConnect/feature/customer/screen/recent_request_screen.dart';

import '../../../route/route_name.dart';
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

  // ───────────────────────── Header ──────────────────────────────────
  Widget _buildHeader(HomeController ctrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Profile Avatar with first letter
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
          // Greeting + Name
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
          // Notification Icon
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
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          // ✅ কোনো boxShadow নেই — plain white
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
                    color: const Color(0xFFBDBDBD), // ✅ light grey
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.white,  // ✅ white background
                  filled: true,
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF212121),
                ),
              ),
            ),
            Icon(
              Icons.search,
              color: const Color(0xFFBDBDBD),
              size: 22.sp,
            ),
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
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
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
              onTap: () {
                Get.toNamed( RouteName.newRequest,
                  arguments: {'serviceId': category['id']},
                );
              },
            );
          },
        ),
      );
    });
  }

  // ───────────────────── Request Card (shared) ───────────────────────
  Widget _buildRequestCard(Map<String, dynamic> item) {
    final status      = item['status'] ?? 'PENDING';
    final displayText = item['display_text'] ?? '';
    final serviceName = item['service_name']?.toString().isNotEmpty == true
        ? item['service_name']
        : 'Service Request';
    final assetPath   = HomeController.assetFromString(item['service_icon'] ?? '');

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
            // Asset Image
            Image.asset(
              assetPath,
              width: 36.w,
              height: 36.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 14.w),
            // Title + Date
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
            // Status Badge
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
    final assetPath = HomeController.assetFromString(category['icon'] ?? '');
    final label     = category['name_en'] ?? '';

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
            Image.asset(
              assetPath,
              width: 44.w,
              height: 44.w,
              fit: BoxFit.contain,
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