import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyRequest extends StatefulWidget {
  const MyRequest({super.key});

  @override
  State<MyRequest> createState() => _MyRequestState();
}

class _MyRequestState extends State<MyRequest> {
  String selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            // App bar
            _buildAppBar(),
            SizedBox(height: 20.h),
            // Tab bar
            _buildTabBar(),
            SizedBox(height: 16.h),
            // Request list
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  SizedBox(height: 4.h),
                  _buildRequestCard(
                    iconPath: 'assets/images/profile/water.png',
                    service: 'Plumbing',
                    date: 'Oct 24, 2023',
                    total: '₪450',
                    distance: '2.3 km',
                    status: 'Completed',
                    statusColor: const Color(0xFF4CAF50),
                    statusBgColor: const Color(0xFFE8F5E9),
                  ),
                  SizedBox(height: 16.h),
                  _buildRequestCard(
                    iconPath: 'assets/images/profile/2.png',
                    service: 'Electrical',
                    date: 'Oct 24, 2023',
                    total: '₪320',
                    distance: '2.3 km',
                    status: 'Completed',
                    statusColor: const Color(0xFF4CAF50),
                    statusBgColor: const Color(0xFFE8F5E9),
                  ),
                  SizedBox(height: 16.h),
                  _buildRequestCard(
                    iconPath: 'assets/images/profile/water.png',
                    service: 'Plumbing',
                    date: 'Oct 24, 2023',
                    total: '₪0',
                    distance: '2.3 km',
                    status: 'Cancelled',
                    statusColor: Colors.white,
                    statusBgColor: const Color(0xFFF44336),
                  ),
                  SizedBox(height: 90.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── App Bar ─────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(
              Icons.arrow_back,
              color: const Color(0xFF212121),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'My Request',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Tab Bar ─────────────────────────────────────
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _buildTab('All'),
          SizedBox(width: 10.w),
          _buildTab('Active'),
          SizedBox(width: 10.w),
          _buildTab('Completed'),
          SizedBox(width: 10.w),
          _buildTab('Cancelled'),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8C106) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF8C106)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Request Card ────────────────────────────────
  Widget _buildRequestCard({
    required String iconPath,
    required String service,
    required String date,
    required String total,
    required String distance,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top row: icon + service + status
          Row(
            children: [
              // Service icon
              Image.asset(
                iconPath,
                width: 40.w,
                height: 40.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 14.w),
              // Service name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12.sp,
                          color: const Color(0xFFBDBDBD),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFFBDBDBD),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Divider line
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Divider(
              color: const Color(0xFFEEEEEE),
              height: 1,
              thickness: 1,
            ),
          ),

          // Bottom row: total + distance
          Row(
            children: [
              // Total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      total,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              ),
              // Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.sp,
                        color: const Color(0xFFBDBDBD),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        distance,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}