import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/extra/controller/report_issue_controller.dart';




class ReportIssueDialog extends StatelessWidget {
  final ReportIssueController controller;
  final String jobType;

  const ReportIssueDialog({
    super.key,
    required this.controller,
    this.jobType = 'Plumbing',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Issue with Lead',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        jobType,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16.sp, color: const Color(0xFF757575)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(height: 16.h),

            // ── Reason options ─────────────────────────────────
            Obx(() => Column(
              children: List.generate(
                controller.reasons.length,
                    (index) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _buildReasonOption(index),
                ),
              ),
            )),
            SizedBox(height: 14.h),

            // ── Additional details ─────────────────────────────
            Text(
              'Additional details (optional)',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF757575)),
            ),
            SizedBox(height: 8.h),
            Container(
              height: 110.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: TextField(
                controller: controller.additionalDetailsController,
                maxLines: null,
                expands: true,
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF212121)),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12.w),
                  hintText: 'Describe the issue...',
                  hintStyle: TextStyle(fontSize: 13.sp, color: const Color(0xFFBDBDBD)),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // ── Buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: controller.submitReport,
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(int index) {
    final isSelected = controller.selectedReason.value == index;

    return GestureDetector(
      onTap: () => controller.selectReason(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF2ECC71) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFBDBDBD),
                  width: isSelected ? 6 : 1.5,
                ),
                color: isSelected ? Colors.white : Colors.white,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                controller.reasons[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: const Color(0xFF212121),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}