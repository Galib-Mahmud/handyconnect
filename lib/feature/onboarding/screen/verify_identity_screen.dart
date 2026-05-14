// lib/feature/professional/screen/Onboardingpages/verifyidentity.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/onboarding/controller/onboarding_controller.dart';
import 'package:handyConnect/feature/onboarding/screen/onboarding_screen.dart';


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
            onChoose: c.pickGovernmentId,
          )),

          // Professional Certificate
          Obx(() => _DocCard(
            title: 'Professional Certificate',
            subtitle: 'Trade licenses or relevant certifications',
            icon: Icons.workspace_premium_outlined,
            file: c.certificateFile.value,
            onChoose: c.pickCertificate,
          )),

          // Profile Photo
          Obx(() => _DocCard(
            title: 'Profile Photo',
            subtitle: 'Clear photo of your face for customers',
            icon: Icons.person_outline,
            file: c.profilePhotoFile.value,
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
      bottomButton: PrimaryButton(label: 'Continue Setup', onTap: onNext),
    );
  }
}

// ─── Doc Card ─────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final VoidCallback onChoose;

  const _DocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = file != null;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        border: Border.all(color: uploaded ? kPrimary : kBorderGrey),
        borderRadius: BorderRadius.circular(12.r),
        color: uploaded ? kPrimaryLight : Colors.white,
      ),
      child: Row(
        children: [
          // Show thumbnail if it's an image, else icon
          uploaded
              ? ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Image.file(
              file!,
              width: 36.r,
              height: 36.r,
              fit: BoxFit.cover,
            ),
          )
              : Icon(icon, color: kTextGrey, size: 28.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14.sp)),
                Text(
                  uploaded
                      ? file!.path.split('/').last
                      : subtitle,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: uploaded ? kPrimary : kTextGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChoose,
            child: Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle : Icons.upload_outlined,
                  color: kPrimary,
                  size: 18.r,
                ),
                SizedBox(width: 4.w),
                Text(
                  uploaded ? 'Change' : 'Choose',
                  style: TextStyle(
                      color: kPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}