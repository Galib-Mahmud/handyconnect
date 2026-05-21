// lib/feature/professional/activejob/screen/active_job_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';
import '../controller/active_job_controller.dart';

class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Find controller registered by JobRequestsController ──────
    final c = Get.find<ActiveJobController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context, c),
      body: Obx(() => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            _buildWorkerCard(c),
            SizedBox(height: 12.h),
            _buildJobDetailsCard(c),
            SizedBox(height: 12.h),
            _buildProgressCard(c),
            SizedBox(height: 12.h),

            // Before/After only shown in IN_PROGRESS or COMPLETED
            if (c.showBeforeAfterCard) ...[
              _buildBeforeAfterCard(c),
              SizedBox(height: 12.h),
            ],

            _buildBottomButton(c),
            SizedBox(height: 24.h),
          ],
        ),
      )),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ActiveJobController c) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 18.sp, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Active Job',
        style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      ),
      actions: [
        Obx(() => Container(
          margin: EdgeInsets.only(right: 16.w),
          padding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            c.jobStatus.value,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50)),
          ),
        )),
      ],
    );
  }

  // ─── Worker Card (with chat button) ────────────────────────────
  Widget _buildWorkerCard(ActiveJobController c) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Customer avatar
          Obx(() => CircleAvatar(
            radius: 24.r,
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: c.clientImage.value.isNotEmpty
                ? NetworkImage(c.clientImage.value)
                : null,
            child: c.clientImage.value.isEmpty
                ? Icon(Icons.person, size: 24.sp, color: Colors.grey)
                : null,
          )),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  c.clientName.value,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                      color: Colors.black87),
                )),
                SizedBox(height: 2.h),
                Obx(() => Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13.sp, color: Colors.grey),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        c.clientAddress.value.isNotEmpty
                            ? c.clientAddress.value
                            : 'No address',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),

          // ── Chat button ───────────────────────────────────────
          GestureDetector(
            onTap: () => _openChat(c),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Open Chat ────────────────────────────────────────────────────
  void _openChat(ActiveJobController c) {
    // Create the chat controller with all needed data
    final chatController = ProfessionalChatController(
      requestId  : c.jobId,
      clientName : c.clientName.value,
      jobLabel   : 'Job #${c.jobId}',
      clientPhoto: c.clientImage.value,
      myFullName : c.myName,   // getter added to ActiveJobController below
    );

    // Navigate passing the controller directly — no Get.arguments needed
    Get.to(
          () => ProfessionalChatScreen(controller: chatController),
      transition: Transition.rightToLeft,
    );
  }

  // ─── Job Details Card ─────────────────────────────────────────────
  Widget _buildJobDetailsCard(ActiveJobController c) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Details',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: Colors.black87)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text('Detected Issue',
                  style:
                  TextStyle(fontSize: 12.sp, color: Colors.grey)),
              const Spacer(),
              Obx(() => c.markAsPriority.value
                  ? Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('High Priority',
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE53935))))
                  : const SizedBox.shrink()),
            ],
          ),
          SizedBox(height: 4.h),
          Obx(() => Text(
            c.serviceName.value.isNotEmpty
                ? c.serviceName.value
                : 'Service Request',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                color: Colors.black87),
          )),
          SizedBox(height: 10.h),
          Text('Description',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          SizedBox(height: 4.h),
          Obx(() => Text(
            c.description.value.isNotEmpty
                ? c.description.value
                : '—',
            style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black54,
                height: 1.5),
          )),
          SizedBox(height: 12.h),
          Text('Est. Price',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          SizedBox(height: 4.h),
          Obx(() => Text(
            '${c.estCurrency.value} ${c.estPriceMin.value} – ${c.estPriceMax.value}',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFC107)),
          )),
        ],
      ),
    );
  }

  // ─── Progress Card ─────────────────────────────────────────────────
  Widget _buildProgressCard(ActiveJobController c) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: Colors.black87)),
          SizedBox(height: 16.h),
          Obx(() => Column(
            children: List.generate(c.progressSteps.length, (index) {
              final step   = c.progressSteps[index];
              final isDone = step.status == JobProgressStatus.completed;
              final isActive = step.status == JobProgressStatus.active;
              final isLast = index == c.progressSteps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone || isActive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE0E0E0),
                        ),
                        child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : isActive
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2.w,
                          height: 32.h,
                          color: isDone
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE0E0E0),
                        ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14.sp,
                              color: isActive || isDone
                                  ? Colors.black87
                                  : Colors.grey),
                        ),
                        if (step.subtitle != null)
                          Text(step.subtitle!,
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF4CAF50))),
                        if (isActive && step.subtitle == null)
                          Text('Active now',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF4CAF50))),
                        if (!isLast) SizedBox(height: 18.h),
                      ],
                    ),
                  ),
                ],
              );
            }),
          )),
        ],
      ),
    );
  }

  // ─── Before/After Card ─────────────────────────────────────────────
  Widget _buildBeforeAfterCard(ActiveJobController c) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Before/After Photos',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: Colors.black87)),
          SizedBox(height: 14.h),
          _photoSlot('Bill Image', c.billImagePath, c.pickBillImage),
          SizedBox(height: 12.h),
          _photoSlot('Before', c.beforePhotoPath, c.pickBeforePhoto),
          SizedBox(height: 12.h),
          _photoSlot('After', c.afterPhotoPath, c.pickAfterPhoto),
        ],
      ),
    );
  }

  Widget _photoSlot(
      String label, RxString path, VoidCallback onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onPick,
          child: Obx(() => Container(
            width: double.infinity,
            height: 90.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: path.value.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.file(File(path.value),
                  fit: BoxFit.cover,
                  width: double.infinity),
            )
                : Center(
                child: Icon(Icons.camera_alt_outlined,
                    color: Colors.grey, size: 30.sp)),
          )),
        ),
      ],
    );
  }

  // ─── Bottom Button ─────────────────────────────────────────────────
  Widget _buildBottomButton(ActiveJobController c) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed:
        c.isActionLoading.value ? null : c.onBottomButtonTap,
        icon: c.isActionLoading.value
            ? SizedBox(
          width: 18.w,
          height: 18.w,
          child: const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : Icon(c.bottomButtonIcon, size: 20.sp),
        label: Text(
          c.bottomButtonLabel,
          style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.bottomButtonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          c.bottomButtonColor.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    ));
  }
}