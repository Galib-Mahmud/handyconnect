import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:handyConnect/feature/onboarding/screen/onboarding_screen.dart';

class Screen4ApplicationSubmitted extends StatelessWidget {
  final VoidCallback onHome;
  const Screen4ApplicationSubmitted({super.key, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      step: 3,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withOpacity(0.1),
                  ),
                ),
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "We've received your details and are currently reviewing your application.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: kTextGrey,
                height: 1.5,
              ),
            ),
            SizedBox(height: 28.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderGrey),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                children: [
                  _StatusRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: 'Pending Approval',
                    subtitle: 'Estimated review time: 24-48 hours',
                    status: null,
                  ),
                  Divider(height: 20.h),
                  _StatusRow(
                    icon: Icons.circle,
                    label: 'Account created',
                    status: 'done',
                  ),
                  SizedBox(height: 10.h),
                  _StatusRow(
                    icon: Icons.circle,
                    label: 'Identity verified',
                    status: 'done',
                  ),
                  SizedBox(height: 10.h),
                  _StatusRow(
                    icon: Icons.circle,
                    label: 'Services configured',
                    status: 'done',
                  ),
                  SizedBox(height: 10.h),
                  _StatusRow(
                    icon: Icons.circle,
                    label: 'Admin review',
                    status: 'progress',
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      bottomButton: PrimaryButton(label: 'Next', onTap: onHome),
    );
  }
}


class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? status; // 'done', 'progress', null

  const _StatusRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (status == 'done') {
      trailing = Icon(
        Icons.check_circle,
        color: kPrimary,
        size: 20.sp,
      );
    } else if (status == 'progress') {
      trailing = Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'In Progress',
          style: TextStyle(
            color: kPrimary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(
          status == 'done'
              ? Icons.circle
              : status == 'progress'
              ? Icons.radio_button_unchecked
              : Icons.access_time_rounded,
          color: status == null ? kPrimary : kBorderGrey,
          size: status == null ? 20.sp : 14.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: status == null ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14.sp,
                  color: kTextDark,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: kTextGrey,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
