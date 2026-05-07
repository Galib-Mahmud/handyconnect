import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/route/route_name.dart';

class ApplicationSentScreen extends StatelessWidget {
  const ApplicationSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),

              // ── Circular Green Check ──────────────────────────────
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C853), width: 1.5),
                    ),
                    child: Icon(Icons.check, color: const Color(0xFF00C853), size: 30.sp),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // ── Header ──────────────────────────────────────────
              Text(
                'Application Sent!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "Your request has been submitted. Here's\nwhat happens next.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF667085),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              // ── What Happens Next Card ──────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFF2F4F7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildStepItem(
                      icon: Icons.auto_awesome,
                      iconColor: const Color(0xFFF8C106),
                      bgColor: const Color(0xFFFFF9E7),
                      title: 'Automated Matching',
                      desc: 'Our system is finding the best plumbers in your area based on your zip code and issue type.',
                    ),
                    SizedBox(height: 24.h),
                    _buildStepItem(
                      icon: Icons.mail_outline,
                      iconColor: const Color(0xFF2E90FA),
                      bgColor: const Color(0xFFEFF8FF),
                      title: 'Request Emailed to Providers',
                      desc: 'A limited number of matching service providers will receive your request with a link to your media.',
                    ),
                    SizedBox(height: 24.h),
                    _buildStepItem(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF7E57C2),
                      bgColor: const Color(0xFFF4F3FF),
                      title: 'Providers Respond',
                      desc: 'Interested providers will reach out to you directly with their quote and availability.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // ── Your Request Summary Card ───────────────────────
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Request',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildInfoRow('Issue', 'Burst Pipe (Under Sink)'),
                    SizedBox(height: 12.h),
                    _buildInfoRow('Professional', 'Plumber'),
                    SizedBox(height: 12.h),
                    _buildInfoRow('Providers Notified', 'Up to 5 nearby'),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // ── Info Message ────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFD1FADF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: const Color(0xFF039855), size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Free & non-binding — you're under no obligation to accept any quote.",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF039855),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              // ── Done Button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed:  () {
                    Get.toNamed(RouteName.directHire);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8C106),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939))),
              SizedBox(height: 4.h),
              Text(desc, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF667085), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, color: const Color(0xFF667085))),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1D2939))),
      ],
    );
  }
}