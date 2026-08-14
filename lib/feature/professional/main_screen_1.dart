
import 'package:VonAbisZ/feature/professional/screen/earning_screen.dart';
import 'package:VonAbisZ/feature/professional/screen/job_request_screen.dart';
import 'package:VonAbisZ/feature/professional/screen/professional_home_screen.dart';
import 'package:VonAbisZ/feature/professional/screen/professional_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';






class MainScreen1 extends StatefulWidget {
  const MainScreen1({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen1> createState() => _MainScreen1State();
}

class _MainScreen1State extends State<MainScreen1> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    ProfessionalHomeScreen(),
    JobRequestsScreen(),
    EarningsScreen(),
    ProfessionalProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconPath: 'assets/images/auth/home.png',
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            iconPath: 'assets/images/auth/request.png',
            label: 'Request',
            index: 1,
          ),_buildNavItem(
            iconPath: 'assets/images/splash/doller.png',
            label: 'Earnings',
            index: 2,
          ),
          _buildNavItem(
            iconPath: 'assets/images/auth/profile.png',
            label: 'Profile',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Yellow top indicator bar
            Container(
              width: 30.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFF8C106)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
            // Icon
            Image.asset(
              iconPath,
              width: 24.sp,
              height: 24.sp,
              color: isActive
                  ? const Color(0xFFF8C106)
                  : const Color(0xFF9E9E9E),
            ),
            SizedBox(height: 4.h),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isActive
                    ? const Color(0xFFF8C106)
                    : const Color(0xFF9E9E9E),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}