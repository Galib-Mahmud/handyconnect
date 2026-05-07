// lib/feature/customer/profile/views/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../route/route_name.dart';
import '../controller/profile_controller.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Obx(() {
          // ── Full-screen loader on first load ───────────────────
          if (c.isLoading.value && c.userName.value.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF8C106)),
            );
          }

          return Column(
            children: [
              SizedBox(height: 16.h),
              _buildHeader(context, c),
              Divider(height: 1, color: const Color(0xFFEEEEEE)),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFF8C106),
                  onRefresh: c.fetchCustomerHomepage,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // ── Profile Card ──────────────────────────
                        _buildProfileCard(c),
                        SizedBox(height: 16.h),

                        // ── Menu Items ────────────────────────────
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Saved Addresses',
                          subtitle: '3 saved',
                          onTap: () {
                            Get.toNamed(RouteName.savedAddresses);

                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'On',
                          onTap: () {

                            Get.toNamed(RouteName.notification);

                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildMenuItem(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          subtitle: 'English',
                          onTap: () {},
                        ),
                        SizedBox(height: 32.h),

                        // ── Delete Account ────────────────────────
                        GestureDetector(
                          onTap: () => c.showDeleteAccountDialog(context),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 60.w),
                            padding: EdgeInsets.symmetric(
                                vertical: 14.h, horizontal: 24.w),
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

                        // ── Log Out ───────────────────────────────
                        GestureDetector(
                          onTap: () => c.showLogoutDialog(context),
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
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────── Header ──────────────────────────────────
  Widget _buildHeader(BuildContext context, ProfileController c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, size: 22.sp, color: const Color(0xFF212121)),
          ),
          Text(
            'Profile',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121)),
          ),
          // Reload button
          GestureDetector(
            onTap: c.fetchCustomerHomepage,
            child: Obx(() => c.isLoading.value
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF8C106),
              ),
            )
                : Icon(Icons.refresh_rounded,
                size: 22.sp, color: const Color(0xFF212121))),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Profile Card ────────────────────────────
  Widget _buildProfileCard(ProfileController c) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar — initials fallback since API returns no avatar URL
          Obx(() => Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF8C106).withOpacity(0.15),
              borderRadius: BorderRadius.circular(28.r),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(c.userName.value),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF8C106),
              ),
            ),
          )),
          SizedBox(width: 16.w),
          Obx(() => Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.userName.value.isEmpty ? '—' : c.userName.value,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121)),
                ),
                SizedBox(height: 4.h),
                Text(
                  c.userEmail.value,
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF757575)),
                ),
                SizedBox(height: 2.h),
                Text(
                  c.userPhone.value,
                  style: TextStyle(
                      fontSize: 13.sp, color: const Color(0xFF757575)),
                ),
                SizedBox(height: 4.h),
                // Role badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C106).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    c.userRole.value,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF8C106),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─────────────────────── Menu Item ───────────────────────────────
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: const Color(0xFF424242), size: 22.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121))),
                  SizedBox(height: 4.h),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: const Color(0xFF9E9E9E), size: 16.sp),
          ],
        ),
      ),
    );
  }

  // ─── Helper: first letters of name words ─────────────────────────
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}