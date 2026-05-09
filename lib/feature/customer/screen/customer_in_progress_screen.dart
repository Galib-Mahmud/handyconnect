// lib/features/order/views/customer_in_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/customer_in_progress_controller.dart';

class CustomerInProgressScreen extends StatelessWidget {
  const CustomerInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InProgressController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Obx(() {
          // ── Full-screen loading (first load only) ────────────────
          if (controller.isLoading.value && controller.steps.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF8C106)),
            );
          }

          // ── Full-screen error ────────────────────────────────────
          if (controller.errorMsg.value.isNotEmpty && controller.steps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 48.sp, color: const Color(0xFFBDBDBD)),
                  SizedBox(height: 12.h),
                  Text(
                    controller.errorMsg.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: controller.fetchStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8C106),
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

          // ── Main content ─────────────────────────────────────────
          return Column(
            children: [
              SizedBox(height: 16.h),
              _buildHeader(),
              Divider(height: 24.h, color: const Color(0xFFEEEEEE)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMapView(),
                      SizedBox(height: 16.h),
                      _buildTechnicianCard(controller),
                      SizedBox(height: 24.h),
                      _buildTimeline(controller),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              _buildCancelButton(controller),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────── Header ──────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back,
                size: 22.sp, color: const Color(0xFF212121)),
          ),
          SizedBox(width: 16.w),
          Text(
            'In Progress',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Map View ────────────────────────────────
  Widget _buildMapView() {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(double.infinity, 180.h),
            painter: _MapGridPainter(),
          ),
          _PulsingDot(),
          Text(
            'Map View (On The Way)',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Technician Card ─────────────────────────
  Widget _buildTechnicianCard(InProgressController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Avatar: NetworkImage with fallback ───────────────
              Obx(() {
                final photo = controller.technicianImage.value;
                return CircleAvatar(
                  radius: 26.r,
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage:
                  photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Icon(Icons.person,
                      color: const Color(0xFF9E9E9E), size: 28.sp)
                      : null,
                );
              }),
              SizedBox(width: 14.w),
              // ── Name only (rating/jobs removed — not in API) ─────
              Expanded(
                child: Obx(() => Text(
                  controller.technicianName.value.isEmpty
                      ? 'Loading…'
                      : controller.technicianName.value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                )),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // ── Chat button ─────────────────────────────────────────
          GestureDetector(
            onTap: controller.openChat,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
              child:
              Icon(Icons.chat_bubble, color: Colors.white, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Timeline ────────────────────────────────
  Widget _buildTimeline(InProgressController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Timeline',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        SizedBox(height: 16.h),
        Obx(() => Column(
          children: List.generate(controller.steps.length, (index) {
            return _buildTimelineStep(
              step: controller.steps[index],
              isLast: index == controller.steps.length - 1,
            );
          }),
        )),
      ],
    );
  }

  Widget _buildTimelineStep(
      {required TimelineStep step, required bool isLast}) {
    late Widget leadingIcon;

    switch (step.status) {
      case TimelineStatus.completed:
        leadingIcon = Container(
          width: 36.w,
          height: 36.w,
          decoration: const BoxDecoration(
              color: Color(0xFF43A047), shape: BoxShape.circle),
          child: Icon(Icons.check, color: Colors.white, size: 18.sp),
        );
        break;
      case TimelineStatus.active:
        leadingIcon = Container(
          width: 36.w,
          height: 36.w,
          decoration: const BoxDecoration(
              color: Color(0xFF43A047), shape: BoxShape.circle),
          child: Icon(Icons.access_time, color: Colors.white, size: 18.sp),
        );
        break;
      case TimelineStatus.pending:
        leadingIcon = Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
          ),
        );
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + connector line
          Column(
            children: [
              leadingIcon,
              if (!isLast)
                Container(
                  width: 2.w,
                  height: step.subtitle != null ? 56.h : 32.h,
                  color: step.status == TimelineStatus.pending
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF43A047),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          // Label block
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6.h, bottom: isLast ? 0 : 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: step.status == TimelineStatus.active
                              ? const Color(0xFF43A047)
                              : step.status == TimelineStatus.pending
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF212121),
                        ),
                      ),
                      if (step.time != null)
                        Text(
                          step.time!,
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFBDBDBD)),
                        ),
                    ],
                  ),
                  if (step.subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      step.subtitle!,
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Cancel Button ───────────────────────────
  Widget _buildCancelButton(InProgressController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: GestureDetector(
        onTap: controller.cancelOrder,
        child: Container(
          height: 54.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Map grid painter ────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDD0DA)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}

// ─────────────────── Pulsing animated dot ────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFA726), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                color: Color(0xFFFFA726), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}