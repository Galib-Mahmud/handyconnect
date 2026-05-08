// lib/feature/professional/screen/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controller/subscription_controller.dart';


class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SubscriptionController ctrl = Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // ── Close Button ─────────────────────────────
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(Icons.close,
                          size: 26.sp, color: const Color(0xFF212121)),
                    ),

                    SizedBox(height: 28.h),

                    // ── Title ────────────────────────────────────
                    Text(
                      'Start your 3-day FREE\ntrial to continue.',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        height: 1.25,
                      ),
                    ),

                    SizedBox(height: 36.h),

                    // ── Timeline ─────────────────────────────────
                    _buildTimeline(),

                    SizedBox(height: 40.h),

                    // ── Plan Cards (reactive) ─────────────────────
                    Obx(() => _buildPlanCards(ctrl)),

                    SizedBox(height: 20.h),

                    // ── No Payment Due ───────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check,
                              size: 16.sp,
                              color: const Color(0xFF212121)),
                          SizedBox(width: 6.w),
                          Text(
                            'No Payment Due Now',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // ── CTA Button ───────────────────────────────
                    Obx(() => _buildCtaButton(ctrl)),

                    SizedBox(height: 12.h),

                    // ── Subtitle ─────────────────────────────────
                    Center(
                      child: Text(
                        '3days free then 11,88€ a year',
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF9E9E9E)),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Timeline ────────────────────────────────
  Widget _buildTimeline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: icons + connecting lines
        Column(
          children: [
            _timelineIcon(Icons.lock_outline, filled: true),
            _timelineLine(),
            _timelineIcon(Icons.notifications_none_rounded, filled: true),
            _timelineLine(),
            _timelineIcon(Icons.workspace_premium_outlined, filled: false),
          ],
        ),

        SizedBox(width: 16.w),

        // Right: text blocks
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _timelineText(
                title: 'Today',
                subtitle:
                'Get full access and see your mindset start to change.',
              ),
              SizedBox(height: 32.h),
              _timelineText(
                title: 'Day 2',
                subtitle:
                'Get a reminder that your trial ends in 24 hours',
              ),
              SizedBox(height: 32.h),
              _timelineText(
                title: 'After day 3',
                subtitle:
                "Your free trial ends and you'll be charged, cancel anytime before",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineIcon(IconData icon, {required bool filled}) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? const Color(0xFFF8C106) : const Color(0xFF424242),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _timelineLine() {
    return Container(
      width: 2.w,
      height: 52.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8C106),
            const Color(0xFFF8C106).withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _timelineText({required String title, required String subtitle}) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF757575),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Plan Cards ──────────────────────────────
  Widget _buildPlanCards(SubscriptionController ctrl) {
    final bool yearly = ctrl.isYearly.value;

    return Row(
      children: [
        // Monthly
        Expanded(
          child: GestureDetector(
            onTap: ctrl.selectMonthly,
            child: Container(
              padding:
              EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: !yearly
                      ? const Color(0xFFF8C106)
                      : const Color(0xFFE0E0E0),
                  width: !yearly ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A))),
                      SizedBox(height: 4.h),
                      Text('1.99 €/mo',
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF757575))),
                    ],
                  ),
                  _radioCircle(!yearly),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Yearly
        Expanded(
          child: GestureDetector(
            onTap: ctrl.selectYearly,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: 20.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: yearly
                          ? const Color(0xFFF8C106)
                          : const Color(0xFFE0E0E0),
                      width: yearly ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yearly',
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A))),
                          SizedBox(height: 4.h),
                          Text('0.99 €/mo',
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF757575))),
                        ],
                      ),
                      _radioCircle(yearly),
                    ],
                  ),
                ),

                // "3 days Free" badge
                Positioned(
                  top: -12.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8C106),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '3 days Free',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioCircle(bool selected) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFFF8C106) : Colors.white,
        border: Border.all(
          color: selected
              ? const Color(0xFFF8C106)
              : const Color(0xFFBDBDBD),
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check, color: Colors.white, size: 13.sp)
          : null,
    );
  }

  // ───────────────────────── CTA Button ──────────────────────────────
  Widget _buildCtaButton(SubscriptionController ctrl) {
    return GestureDetector(
      onTap: ctrl.isLoading.value ? null : ctrl.activateSubscription,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: ctrl.isLoading.value
              ? const Color(0xFFF8C106).withOpacity(0.6)
              : const Color(0xFFF8C106),
          borderRadius: BorderRadius.circular(32.r),
        ),
        child: Center(
          child: ctrl.isLoading.value
              ? const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2)
              : Text(
            'Start 3-day free trial',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}