import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:handyConnect/feature/onboarding/screen/onboarding_screen.dart';

class Screen1AccountCreated extends StatelessWidget {
  final VoidCallback onNext;
  const Screen1AccountCreated({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      step: 0,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimary.withOpacity(0.3),
                  width: 8.w,
                ),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: kPrimary,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Account Created',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "Welcome aboard! Let's complete your profile to start receiving service requests.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: kTextGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      bottomButton: PrimaryButton(label: 'Continue Setup', onTap: onNext),
    );
  }
}
