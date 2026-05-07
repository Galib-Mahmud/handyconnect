import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../route/route_name.dart';

class ServiceProviderScreen extends StatelessWidget {
  const ServiceProviderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD), // Slightly off-white
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Custom App Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Service Providers',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D2939),
                    ),
                  ),
                  const Spacer(),
                  // "3 Accepted" Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E7),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '3 Accepted',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF8C106),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),

            // Professional List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(20.w),
                itemCount: 3,
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  return _buildProfessionalCard(
                    name: 'John Mayer',
                    profession: 'Plumber',
                    zipCode: '1234',
                    imagePath: 'assets/images/profile/profile.png',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String name,
    required String profession,
    required String zipCode,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Column(
        children: [
          // Row 1: Badge Section
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: const Color(0xFF00C853), size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Verified Professional',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '100% Trusted',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Row 2: Profile Section
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundImage: AssetImage(imagePath),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.opacity, color: Colors.blue, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text(
                                profession,
                                style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(RouteName.professionalProfile);
                      },
                      child: Icon(
                        Icons.chevron_right,
                        color: const Color(0xFFF8C106),
                        size: 32.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF2F2F2), thickness: 1, height: 1),

          // Row 3: Zip Code & Action Button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zip Code',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    Text(
                      zipCode,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF8C106),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(100.w, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}