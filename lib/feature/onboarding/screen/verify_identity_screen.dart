// lib/feature/onboarding/screen/verify_identity_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../controller/onboarding_controller.dart';
import 'onboarding_screen.dart';

class Screen2VerifyIdentity extends StatelessWidget {
  final VoidCallback onNext;
  const Screen2VerifyIdentity({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingController.to;

    return BaseScreen(
      step: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Your Identity',
            style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: kTextDark),
          ),
          SizedBox(height: 6.h),
          Text(
            'Upload required documents to continue',
            style: TextStyle(fontSize: 14.sp, color: kTextGrey),
          ),
          SizedBox(height: 24.h),

          // Government ID
          Obx(() => _DocCard(
                title: 'Government ID',
                subtitle: "Driver's license, Passport, or National ID",
                icon: Icons.badge_outlined,
                file: c.governmentIdFile.value,
                existingUrl: c.existingGovernmentIdUrl.value,
                onChoose: c.pickGovernmentId,
              )),

          // Professional Certificate
          Obx(() => _DocCard(
                title: 'Professional Certificate',
                subtitle: 'Trade licenses or relevant certifications',
                icon: Icons.workspace_premium_outlined,
                file: c.certificateFile.value,
                existingUrl: c.existingCertificateUrl.value,
                onChoose: c.pickCertificate,
              )),

          // Profile Photo
          Obx(() => _DocCard(
                title: 'Profile Photo',
                subtitle: 'Clear photo of your face for customers',
                icon: Icons.person_outline,
                file: c.profilePhotoFile.value,
                existingUrl: c.existingProfilePhotoUrl.value,
                onChoose: c.pickProfilePhoto,
              )),

          const Spacer(),

          // Progress bar
          Obx(() {
            final count = c.uploadedCount;
            return Column(
              children: [
                Row(
                  children: [
                    Text('Documents uploaded',
                        style: TextStyle(color: kTextGrey, fontSize: 13.sp)),
                    const Spacer(),
                    Text(
                      '$count of 3',
                      style: TextStyle(
                          color: kTextGrey,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                LinearProgressIndicator(
                  value: count / 3,
                  backgroundColor: kBorderGrey,
                  color: kPrimary,
                  minHeight: 4.h,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ],
            );
          }),
          SizedBox(height: 16.h),
        ],
      ),
      bottomButton: Obx(() => PrimaryButton(
            label: 'Continue Setup',
            isLoading: c.isUploadingDocs.value,
            onTap: onNext,
          )),
    );
  }
}

// ─── Doc Card ─────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final String? existingUrl;
  final VoidCallback onChoose;

  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    this.existingUrl,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocalFile = file != null;
    final bool hasRemoteFile = existingUrl != null && existingUrl!.isNotEmpty;
    final bool uploaded = hasLocalFile || hasRemoteFile;

    String displaySubtitle = subtitle;
    if (hasLocalFile) {
      displaySubtitle = file!.path.split('/').last;
    } else if (hasRemoteFile) {
      displaySubtitle = 'Document uploaded on file';
    }

    Widget leadingWidget;
    if (hasLocalFile) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.file(
          file!,
          width: 36.r,
          height: 36.r,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasRemoteFile) {
      final fullUrl = ApiEndpoint.mediaUrl(existingUrl!);
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Image.network(
          fullUrl,
          width: 36.r,
          height: 36.r,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.verified_outlined,
            color: const Color(0xFF43A047),
            size: 28.r,
          ),
        ),
      );
    } else {
      leadingWidget = Icon(icon, color: kTextGrey, size: 28.r);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        border: Border.all(
          color: uploaded ? kPrimary : kBorderGrey,
          width: uploaded ? 1.5.w : 1.w,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: uploaded ? kPrimaryLight : Colors.white,
      ),
      child: Row(
        children: [
          leadingWidget,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: kTextDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  displaySubtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: uploaded ? const Color(0xFF2E7D32) : kTextGrey,
                    fontWeight: uploaded ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onChoose,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: uploaded ? Colors.white : kPrimary,
                borderRadius: BorderRadius.circular(8.r),
                border: uploaded ? Border.all(color: kPrimary) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    uploaded ? Icons.refresh : Icons.upload_outlined,
                    color: uploaded ? kPrimary : Colors.white,
                    size: 16.r,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    uploaded ? 'Change' : 'Choose',
                    style: TextStyle(
                      color: uploaded ? kPrimary : Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}