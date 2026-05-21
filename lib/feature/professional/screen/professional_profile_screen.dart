// lib/features/professional/profile/view/professional_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/professional/controller/professional_home_controller.dart';
import 'package:handyConnect/feature/professional/controller/professional_profile_controller.dart';
import 'package:handyConnect/route/route_name.dart';

class ProfessionalProfileScreen extends StatelessWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c  = Get.put(ProfessionalHomeController());
    final pc = Get.put(ProfessionalProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            const _Header(),
            Divider(height: 20.h, color: const Color(0xFFEEEEEE)),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF8C106)),
                  );
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      _ProfileCard(c: c),
                      SizedBox(height: 16.h),
                      _StatsRow(c: c),
                      SizedBox(height: 24.h),
                      const _SubscriptionCard(),
                      SizedBox(height: 24.h),
                      _VerificationsSection(c: c),
                      SizedBox(height: 24.h),
                      _BioSection(c: c),
                      SizedBox(height: 8.h),

                      // ── Delete Account ──────────────────────────
                      GestureDetector(
                        onTap: () => pc.showDeleteAccountDialog(context),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 40.w),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                                color: const Color(0xFFE53935), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline,
                                  color: const Color(0xFFE53935), size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── Log Out ─────────────────────────────────
                      GestureDetector(
                        onTap: () => pc.showLogoutDialog(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: const Color(0xFFE53935), size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
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
            'My Profile',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.c});
  final ProfessionalHomeController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: c.professionalImage.value.isNotEmpty
                    ? Image.network(
                  c.professionalImage.value,
                  width: 54.w,
                  height: 54.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _avatarFallback(c.professionalName.value),
                )
                    : _avatarFallback(c.professionalName.value),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Obx(() => Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: c.isOnline.value
                        ? const Color(0xFF43A047)
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                )),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.professionalName.value,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212121),
                        ),
                      ),
                    ),
                    if (c.isVerified.value)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: const Color(0xFF43A047), size: 12.sp),
                            SizedBox(width: 3.w),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF43A047),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  c.professionalEmail.value,
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
                ),
                SizedBox(height: 4.h),
                Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: c.isAvailable.value
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    c.isAvailable.value ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: c.isAvailable.value
                          ? const Color(0xFF43A047)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1565C0)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.c});
  final ProfessionalHomeController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: Icon(Icons.flash_on,
                  color: const Color(0xFFE53935), size: 18.sp),
            ),
            value: '${c.emergencyCount.value}',
            label: 'Emergency',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline,
                  color: const Color(0xFF43A047), size: 18.sp),
            ),
            value: '${c.jobsCount.value}',
            label: 'Jobs',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: Icon(Icons.star_border,
                  color: const Color(0xFFF8C106), size: 18.sp),
            ),
            value: c.rating.value.toStringAsFixed(1),
            label: 'Rating',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatCard(
            iconWidget: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD), shape: BoxShape.circle),
              child: Icon(Icons.workspace_premium_outlined,
                  color: const Color(0xFF1565C0), size: 18.sp),
            ),
            value: '${c.certificates.value}',
            label: 'Certs',
          ),
        ),
      ],
    ));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.iconWidget, required this.value, required this.label});
  final Widget iconWidget;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          iconWidget,
          SizedBox(height: 8.h),
          Text(value,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF212121))),
          SizedBox(height: 2.h),
          Text(label,
              style:
              TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscription Card
// ─────────────────────────────────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteName.subscription),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8C106), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF8C106).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium,
                  color: Colors.white, size: 26.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Subscription',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'View your plan, benefits & renewal date',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '⭐ Pro Plan — Active',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 28.sp),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verifications Section
// ─────────────────────────────────────────────────────────────────────────────
class _VerificationsSection extends StatelessWidget {
  const _VerificationsSection({required this.c});
  final ProfessionalHomeController c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    color: const Color(0xFF43A047), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Verifications',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
              ],
            ),
            Obx(() => Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: c.isVerified.value
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: c.isVerified.value
                      ? const Color(0xFF43A047)
                      : const Color(0xFFBDBDBD),
                  width: 1,
                ),
              ),
              child: Text(
                c.isVerified.value ? '100% Trusted' : 'Pending',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: c.isVerified.value
                      ? const Color(0xFF43A047)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            )),
          ],
        ),
        SizedBox(height: 14.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Obx(() => _VerificationTile(
                icon: Icons.verified_user,
                iconColor: const Color(0xFF1565C0),
                iconBg: const Color(0xFFE3F2FD),
                title: 'Government ID',
                subtitle: c.isVerified.value
                    ? 'Identity verified'
                    : 'Verification pending',
                isVerified: c.isVerified.value,
              )),
              Divider(
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: const Color(0xFFEEEEEE)),
              Obx(() => _VerificationTile(
                icon: Icons.workspace_premium,
                iconColor: const Color(0xFFF8C106),
                iconBg: const Color(0xFFFFF8E1),
                title: 'Certificates',
                subtitle: c.certificates.value > 0
                    ? '${c.certificates.value} certificate(s) on file'
                    : 'No certificates uploaded',
                isVerified: c.certificates.value > 0,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isVerified,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121))),
                SizedBox(height: 3.h),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isVerified
                ? const Color(0xFF43A047)
                : const Color(0xFFBDBDBD),
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bio Section
// ─────────────────────────────────────────────────────────────────────────────
class _BioSection extends StatelessWidget {
  const _BioSection({required this.c});
  final ProfessionalHomeController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bio = c.professionalBio.value;
      if (bio.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121))),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              bio,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF424242),
                  height: 1.6),
            ),
          ),
        ],
      );
    });
  }
}