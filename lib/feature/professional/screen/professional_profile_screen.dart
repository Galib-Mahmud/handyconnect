
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/professional_profile_controller.dart';





class ProfessionalProfileScreen extends StatelessWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfessionalProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _buildHeader(),
            Divider(height: 20.h, color: const Color(0xFFEEEEEE)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    _buildProfileCard(c),
                    SizedBox(height: 16.h),
                    _buildStatsRow(c),
                    SizedBox(height: 24.h),
                    _buildVerificationsSection(c),
                    SizedBox(height: 24.h),
                    _buildRecentReviews(c),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, size: 22.sp, color: const Color(0xFF212121)),
          ),
          SizedBox(width: 16.w),
          Text(
            'Professional',
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

  // ─────────────────────── Profile Card ──────────────────────────
  Widget _buildProfileCard(ProfessionalProfileController c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Image.asset(
                  'assets/images/profile/profile.png',
                  width: 54.w,
                  height: 54.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    child: Icon(Icons.person, size: 28.sp, color: const Color(0xFF9E9E9E)),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name.value,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
              SizedBox(height: 4.h),
              Text(c.email.value,
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E))),
            ],
          )),
        ],
      ),
    );
  }

  // ─────────────────────── Stats Row ─────────────────────────────
  Widget _buildStatsRow(ProfessionalProfileController c) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
              child: Icon(Icons.trending_up, color: const Color(0xFF1E88E5), size: 18.sp),
            ),
            value: c.radiusKm.value,
            label: 'Radius',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline, color: const Color(0xFF43A047), size: 18.sp),
            ),
            value: '${c.totalJobs.value}',
            label: 'Jobs',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: Icon(Icons.star_border, color: const Color(0xFFF8C106), size: 18.sp),
            ),
            value: '${c.rating.value}',
            label: 'Review',
          ),
        ),
      ],
    ));
  }

  Widget _buildStatCard({required Widget iconWidget, required String value, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          iconWidget,
          SizedBox(height: 10.h),
          Text(value,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: const Color(0xFF212121))),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  // ─────────────────────── Verifications ─────────────────────────
  Widget _buildVerificationsSection(ProfessionalProfileController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: const Color(0xFF43A047), size: 20.sp),
                SizedBox(width: 8.w),
                Text('Verifications',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF43A047), width: 1),
              ),
              child: Text('100% Trusted',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF43A047))),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Obx(() => Row(
                children: [
                  _buildTab(
                    icon: Icons.verified_user_outlined,
                    label: 'Government ID',
                    isSelected: c.selectedTab.value == 0,
                    onTap: () => c.selectTab(0),
                  ),
                  _buildTab(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Certificates',
                    isSelected: c.selectedTab.value == 1,
                    onTap: () => c.selectTab(1),
                  ),
                ],
              )),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Obx(() => c.selectedTab.value == 0 ? _buildGovernmentIdTab() : _buildCertificatesTab()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF43A047) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp,
                  color: isSelected ? const Color(0xFF43A047) : const Color(0xFF9E9E9E)),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF43A047) : const Color(0xFF9E9E9E),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGovernmentIdTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: const Color(0xFF43A047), size: 20.sp),
                  SizedBox(width: 8.w),
                  Text('Verified Identity',
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text('Verified',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C106),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.verified_user, color: Colors.white, size: 26.sp),
                ),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('National ID (NID)',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
                    SizedBox(height: 4.h),
                    Text('Government Database Verified',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
                    SizedBox(height: 2.h),
                    Text('Issued: January 2020',
                        style: TextStyle(fontSize: 11.sp, color: const Color(0xFFBDBDBD))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: Text('No certificates on file.',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E))),
      ),
    );
  }

  // ─────────────────────── Recent Reviews ────────────────────────
  Widget _buildRecentReviews(ProfessionalProfileController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Reviews',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
            GestureDetector(
              onTap: () {

              },
              child: Text('View All',
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E))),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(() => Column(
          children: c.reviews
              .map((r) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildReviewCard(r),
          ))
              .toList(),
        )),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel r) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(r.initials,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.name,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700, color: const Color(0xFF212121))),
                    SizedBox(width: 8.w),
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < r.stars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF8C106),
                          size: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(r.comment,
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}