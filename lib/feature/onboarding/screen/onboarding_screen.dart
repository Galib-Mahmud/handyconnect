import 'package:VonAbisZ/feature/onboarding/screen/setupservices.dart';
import 'package:VonAbisZ/feature/onboarding/screen/verify_identity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../route/route_name.dart';
import '../controller/onboarding_controller.dart';
import 'account_created_onboarding_screen.dart';
import 'applicationsubmitted_screen.dart';




class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  late final OnboardingController _c;

  @override
  void initState() {
    super.initState();
    _c = OnboardingController.to;
    _c.resetSubmitSuccess();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Step 4 button → Subscription screen
  void _goToSubscription() {
    Get.toNamed(RouteName.signin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          // Step 1: Account Created
          Screen1AccountCreated(onNext: _nextStep),

          // Step 2: Verify Identity (Document Upload)
          Screen2VerifyIdentity(
            onNext: () {
              if (_c.validateDocuments()) _nextStep();
            },
          ),

          // Step 3: Setup Services (API Submission)
          Screen3SetupServices(
            onNext: () async {
              await _c.submitOnboarding();
              if (_c.onboardingSubmitSuccess) {
                _c.resetSubmitSuccess();
                _nextStep();
              }
            },
          ),

          // Step 4: Application Submitted → goes to Subscription
          Screen4ApplicationSubmitted(onHome: _goToSubscription),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// SHARED CONSTANTS & WIDGETS
// ───────────────────────────────────────────────────────────────────

const kPrimary      = Color(0xFFF5A623);
const kPrimaryLight = Color(0xFFFFF3DC);
const kTextDark     = Color(0xFF1A1A1A);
const kTextGrey     = Color(0xFF888888);
const kBorderGrey   = Color(0xFFE0E0E0);

class StepIndicator extends StatelessWidget {
  final int currentStep;
  const StepIndicator({super.key, required this.currentStep});

  static const List<String> labels = ['Account', 'Identity', 'Services', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4.w : 0),
                height: 4.h,
                decoration: BoxDecoration(
                  color: i <= currentStep ? kPrimary : kBorderGrey,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) {
            final isActive = i <= currentStep;
            return Column(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: isActive ? kPrimary : kBorderGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : kTextGrey,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isActive ? kPrimary : kTextGrey,
                    fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimary.withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Text(
          label,
          style: TextStyle(
              fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class BaseScreen extends StatelessWidget {
  final int step;
  final Widget body;
  final Widget bottomButton;
  const BaseScreen({
    super.key,
    required this.step,
    required this.body,
    required this.bottomButton,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepIndicator(currentStep: step),
            SizedBox(height: 24.h),
            Expanded(child: body),
            bottomButton,
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}