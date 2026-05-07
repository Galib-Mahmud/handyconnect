// lib/features/order/views/recent_request_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/recent_request_controller.dart';
import 'in_progress_screen.dart';

class RecentRequestScreen extends StatelessWidget {
  const RecentRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RecentRequestController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            _AppBar(c: c),
            SizedBox(height: 16.h),
            Divider(color: const Color(0xFFEEEEEE), thickness: 1, height: 1),
            SizedBox(height: 8.h),
            Expanded(child: _Body(c: c)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.c});
  final RecentRequestController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back,
                color: const Color(0xFF212121), size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'Recent Request',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
            ),
          ),
          // Refresh button / spinner
          Obx(() => c.isLoading.value
              ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF212121),
            ),
          )
              : GestureDetector(
            onTap: c.fetchRequests,
            child: Icon(Icons.refresh,
                size: 22.sp, color: const Color(0xFF212121)),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — loading / error / empty / list
// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  const _Body({required this.c});
  final RecentRequestController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Loading ──────────────────────────────────────────────────
      if (c.isLoading.value && c.requests.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        );
      }

      // ── Error ────────────────────────────────────────────────────
      if (c.errorMessage.value.isNotEmpty && c.requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48.sp, color: const Color(0xFFBDBDBD)),
              SizedBox(height: 12.h),
              Text(
                c.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: c.fetchRequests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Text('Retry',
                    style:
                    TextStyle(fontSize: 14.sp, color: Colors.white)),
              ),
            ],
          ),
        );
      }

      // ── Empty ────────────────────────────────────────────────────
      if (c.requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 52.sp, color: const Color(0xFFBDBDBD)),
              SizedBox(height: 12.h),
              Text(
                'No recent requests yet.',
                style: TextStyle(
                    fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
              ),
            ],
          ),
        );
      }

      // ── List ─────────────────────────────────────────────────────
      return RefreshIndicator(
        color: const Color(0xFF1565C0),
        onRefresh: c.fetchRequests,
        child: ListView.builder(
          padding:
          EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          itemCount: c.requests.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _RequestCard(request: c.requests[index]),
            );
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Card
// ─────────────────────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final RecentRequestModel request;

  // Parse hex colour string → Color
  Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // service_name is "" in the API — fall back to a capitalised icon name
    final title = request.serviceName.isNotEmpty
        ? request.serviceName
        : _iconFallbackName(request.serviceIcon);

    return GestureDetector(
      onTap: () => Get.to(() => const InProgressScreen(),
          arguments: {'requestId': request.id}),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Service icon
            Image.asset(
              request.iconAsset,
              width: 36.w,
              height: 36.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 14.w),

            // Title + display text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    request.displayText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // Status badge
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _hex(request.badgeBg),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                request.statusLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: _hex(request.badgeFg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _iconFallbackName(String icon) {
    const map = {
      'water_drop'     : 'Plumbing',
      'bolt'           : 'Electrical',
      'ac_unit'        : 'AC Repair',
      'palette'        : 'Painting',
      'local_shipping' : 'Moving',
      'eco'            : 'Gardening',
    };
    return map[icon] ?? 'Service';
  }
}