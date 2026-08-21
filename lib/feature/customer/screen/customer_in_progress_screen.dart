import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../route/route_name.dart';
import '../controller/customer_in_progress_controller.dart';
import '../controller/location_tracking_controller.dart'; // adjust path if needed

class CustomerInProgressScreen extends StatelessWidget {
  const CustomerInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InProgressController());
    final trackingController = Get.put(
      LocationTrackingController(requestId: controller.requestId),
      tag: 'tracking_${controller.requestId}',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.steps.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF8C106)),
            );
          }

          if (controller.errorMsg.value.isNotEmpty &&
              controller.steps.isEmpty) {
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
                      _buildMapView(trackingController),
                      SizedBox(height: 16.h),
                      _buildTechnicianCard(controller),
                      SizedBox(height: 16.h),

                      // ── Interested Providers (PENDING only) ────
                      Obx(() {
                        if (controller.currentStatus.value != 'PENDING') {
                          return const SizedBox.shrink();
                        }
                        if (controller.interestedProviders.isEmpty &&
                            !controller.isLoadingProviders.value) {
                          return const SizedBox.shrink();
                        }
                        return _buildInterestedSection(controller);
                      }),

                      SizedBox(height: 8.h),
                      _buildTimeline(controller),
                      SizedBox(height: 24.h),

                      // ── Review (always shown) ──────────────────
                      _buildReviewCard(controller),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(controller),
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

  // ─────────────────────── Map View ─────────────────────────────────
  Widget _buildMapView(LocationTrackingController tracking) {
    return Container(
      height: 180.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Obx(() {
        final jobLat = tracking.jobLat.value;
        final jobLng = tracking.jobLng.value;

        if (jobLat == null || jobLng == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF8C106)),
          );
        }

        final jobLatLng = LatLng(jobLat, jobLng);
        final markers = <Marker>{
          Marker(
            markerId: const MarkerId('job'),
            position: jobLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: tracking.jobAddress.value.isEmpty
                  ? 'Job location'
                  : tracking.jobAddress.value,
            ),
          ),
        };

        if (tracking.hasProviderFix) {
          markers.add(
            Marker(
              markerId: const MarkerId('provider'),
              position: LatLng(
                tracking.providerLat.value!,
                tracking.providerLng.value!,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(
                title: tracking.isProviderStale
                    ? 'Provider (may be outdated)'
                    : 'Provider',
              ),
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: jobLatLng,
                zoom: 14,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _MapStatusChip(tracking: tracking),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────── Technician Card ───────────────────────────
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

  // ─────────────────────── Interested Providers ──────────────────────
  Widget _buildInterestedSection(InProgressController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Interested Providers',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => Container(
              padding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8C106).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${controller.interestedProviders.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF8C106),
                ),
              ),
            )),
            const Spacer(),
            Obx(() => controller.isLoadingProviders.value
                ? SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFF8C106)),
            )
                : const SizedBox.shrink()),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(() {
          if (controller.interestedProviders.isEmpty) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Center(
                child: Text(
                  'No providers yet — hang tight!',
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
                ),
              ),
            );
          }

          return Column(
            children: controller.interestedProviders
                .map((p) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _buildProviderCard(controller, p),
            ))
                .toList(),
          );
        }),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildProviderCard(
      InProgressController controller, Map<String, dynamic> provider) {
    final int id = provider['id'] as int? ?? 0;
    final String name = (provider['full_name'] as String?) ?? 'Professional';
    final String? photo = provider['profile_photo'] as String?;
    final bool verified = (provider['is_verified'] as bool?) ?? false;
    final String rating = (provider['rating'] as String?) ?? '0.00';
    final String? zip = provider['zip_code'] as String?;

    String? fullPhoto;
    if (photo != null && photo.isNotEmpty) {
      fullPhoto = photo.startsWith('http')
          ? photo
          : 'https://handyapi.dsrt321.online$photo';
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF2F4F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: const Color(0xFFF2F4F7),
                backgroundImage:
                fullPhoto != null ? NetworkImage(fullPhoto) : null,
                child: fullPhoto == null
                    ? Icon(Icons.person, color: Colors.grey, size: 24.sp)
                    : null,
              ),
              if (verified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 8.sp),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: const Color(0xFFF8C106), size: 14.sp),
                    SizedBox(width: 3.w),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                    if (zip != null && zip.isNotEmpty) ...[
                      SizedBox(width: 10.w),
                      Icon(Icons.location_on_outlined,
                          size: 12.sp, color: const Color(0xFF9E9E9E)),
                      SizedBox(width: 2.w),
                      Text(
                        zip,
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            final hiring = controller.isHiring.value;
            return GestureDetector(
              onTap: hiring ? null : () => _confirmHire(controller, id, name),
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: hiring
                      ? const Color(0xFFF8C106).withOpacity(0.5)
                      : const Color(0xFFF8C106),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: hiring
                      ? null
                      : [
                    BoxShadow(
                      color: const Color(0xFFF8C106).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: hiring
                    ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  'Hire',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Hire confirmation dialog ────────────────────────────────────
  void _confirmHire(
      InProgressController controller, int providerId, String name) {
    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Hire $name?',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        content: Text(
          'This will assign $name to your request. They will be notified immediately.',
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF667085)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style:
              TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.hireProvider(providerId, name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8C106),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'Hire',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Review Card ───────────────────────────────
  Widget _buildReviewCard(InProgressController controller) {
    return Obx(() {
      // Already reviewed → thank-you state
      if (controller.hasReviewed.value) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16.r),
            border:
            Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: const Color(0xFF43A047), size: 44.sp),
              SizedBox(height: 12.h),
              Text(
                'Thank you for your review!',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your feedback helps others choose the right professional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.sp, color: const Color(0xFF667085)),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write Your Review',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D2939),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Share your experience to help others make better decisions.',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF667085),
                  height: 1.4),
            ),
            SizedBox(height: 20.h),

            // ── Rating label ──
            Row(
              children: [
                Text(
                  'Rate your service',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                ),
                Text(' *',
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFFE53935))),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Stars ──
            Row(
              children: [
                ...List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => controller.setRating(star),
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Icon(
                        star <= controller.reviewRating.value
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF8C106),
                        size: 38.sp,
                      ),
                    ),
                  );
                }),
                SizedBox(width: 6.w),
                Text(
                  controller.reviewRating.value == 0
                      ? '(tap to select)'
                      : '${controller.reviewRating.value}.0',
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
            SizedBox(height: 22.h),

            // ── Comment label ──
            Row(
              children: [
                Text(
                  'Write Your Review',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D2939),
                  ),
                ),
                Text(' *',
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFFE53935))),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Comment field ──
            TextField(
              maxLines: 4,
              onChanged: (v) => controller.reviewComment.value = v,
              style:
              TextStyle(fontSize: 14.sp, color: const Color(0xFF212121)),
              decoration: InputDecoration(
                hintText:
                'Describe what you liked, the service quality, and if you recommend the professional…',
                hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFFB0B5BC),
                    height: 1.5),
                filled: true,
                fillColor: const Color(0xFFFBFBFC),
                contentPadding: EdgeInsets.all(16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                  const BorderSide(color: Color(0xFFF8C106), width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Minimum 10 characters',
                    style: TextStyle(
                        fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
                Obx(() => Text(
                  '${controller.reviewComment.value.length} char',
                  style: TextStyle(
                      fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
                )),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Submit ──
            Obx(() {
              final submitting = controller.isSubmittingReview.value;
              return GestureDetector(
                onTap: submitting ? null : controller.submitReview,
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: submitting
                        ? const Color(0xFFF8C106).withOpacity(0.6)
                        : const Color(0xFFF8C106),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  alignment: Alignment.center,
                  child: submitting
                      ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  // ─────────────────────── Timeline ──────────────────────────────────
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

  // ─────────────────────── Bottom Buttons ────────────────────────────
  Widget _buildBottomButtons(InProgressController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Obx(() {
        final reviewed = controller.currentStatus.value == 'REVIEWED';
        return Column(
          children: [
            // Cancel hide korbo jodi already reviewed (job sesh)
            if (!reviewed) ...[
              GestureDetector(
                onTap: controller.cancelOrder,
                child: Container(
                  width: double.infinity,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                        color: const Color(0xFFFFCDD2), width: 1.5),
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
              SizedBox(height: 12.h),
            ],
            // Go to Home
            GestureDetector(
              onTap: () => Get.offAllNamed(RouteName.main),
              child: Container(
                width: double.infinity,
                height: 54.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8C106),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Go to Home',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────── Map status chip ────────────────────────────────
class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({required this.tracking});

  final LocationTrackingController tracking;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String text;
      Color color;

      switch (tracking.connectionState.value) {
        case TrackingConnectionState.live:
          text = tracking.hasProviderFix
              ? (tracking.isProviderStale ? 'May be outdated' : 'Live')
              : 'Waiting for location…';
          color = tracking.isProviderStale
              ? const Color(0xFFFFA726)
              : const Color(0xFF43A047);
          break;
        case TrackingConnectionState.connecting:
        case TrackingConnectionState.fallbackPolling:
          text = 'Connecting…';
          color = const Color(0xFFFFA726);
          break;
        case TrackingConnectionState.stopped:
          text = 'Tracking ended';
          color = const Color(0xFF9E9E9E);
          break;
        case TrackingConnectionState.error:
          text = 'Unavailable';
          color = const Color(0xFFE53935);
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}