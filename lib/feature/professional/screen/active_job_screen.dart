import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:handyConnect/route/route_name.dart';


class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Column(
          children: [
            _buildWorkerCard(),
            SizedBox(height: 12.h),
            _buildJobDetailsCard(),
            SizedBox(height: 12.h),
            _buildProgressCard(currentStep: 0),
            SizedBox(height: 12.h),
            _buildBottomButton(
              label: "I'm on My Way",
              icon: Icons.check_circle_outline,
              color: const Color(0xFFFFC107),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActiveJobScreen2(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 2: "Start Job" ───────────────────────────────────────────────────
class ActiveJobScreen2 extends StatelessWidget {
  const ActiveJobScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Column(
          children: [
            _buildWorkerCard(),
            SizedBox(height: 12.h),
            _buildJobDetailsCard(),
            SizedBox(height: 12.h),
            _buildProgressCard(currentStep: 1),
            SizedBox(height: 12.h),
            _buildBottomButton(
              label: 'Start Job',
              icon: Icons.check_circle_outline,
              color: const Color(0xFFFFC107),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActiveJobScreen3(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 3: "Complete Job" ─────────────────────────────────────────────────
class ActiveJobScreen3 extends StatelessWidget {
  const ActiveJobScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Column(
          children: [
            _buildWorkerCard(),
            SizedBox(height: 12.h),
            _buildJobDetailsCard(),
            SizedBox(height: 12.h),
            _buildProgressCard(currentStep: 2),
            SizedBox(height: 12.h),
            _buildBeforeAfterCard(),
            SizedBox(height: 12.h),
            _buildBottomButton(
              label: 'Complete Job',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF4CAF50),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActiveJobScreen4(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 4: "Back to Home" ─────────────────────────────────────────────────
class ActiveJobScreen4 extends StatelessWidget {
  const ActiveJobScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        child: Column(
          children: [
            _buildWorkerCard(),
            SizedBox(height: 12.h),
            _buildJobDetailsCard(),
            SizedBox(height: 12.h),
            _buildProgressCard(currentStep: 3),
            SizedBox(height: 12.h),
            _buildBeforeAfterCard(),
            SizedBox(height: 12.h),
            _buildBottomButton(
              label: 'Back to Home',
              icon: Icons.check_circle_outline,
              color: const Color(0xFFFFC107),
              onPressed: () {
                Get.toNamed(RouteName.main1);

              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18.sp,
        color: Colors.black87,
      ),
      onPressed: () => Navigator.maybePop(context),
    ),
    title: Text(
      'Active Job',
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    actions: [
      Container(
        margin: EdgeInsets.only(right: 16.w),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 4.h,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'Accepted',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ),
    ],
  );
}

Widget _buildWorkerCard() {
  return Container(
    padding: EdgeInsets.all(14.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: const Color(0xFFE3F2FD),
          child: CircleAvatar(
            radius: 24.r,
            backgroundImage: const AssetImage(
              'assets/images/professional/imgas.jpg',
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Michael Ben',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 13.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '23 Dowingoft St, Tel Aviv',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
      ],
    ),
  );
}

Widget _buildJobDetailsCard() {
  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Text(
              'Detected Issue',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'High Severity',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Burst Pipe (Under Sink)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Suggested Cause',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Likely caused by corrosion or high water pressure affecting the joint connection. Immediate attention recommended to prevent water damage.',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Est. Price',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '\$350 – \$500',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFFFC107),
          ),
        ),
      ],
    ),
  );
}

Widget _buildProgressCard({required int currentStep}) {
  final steps = ['Accepted', 'On The Way', 'In Progress', 'Completed'];

  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),
        ...List.generate(steps.length, (index) {
          final isDone = index < currentStep;
          final isActive = index == currentStep;
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE0E0E0),
                    ),
                    child: Icon(
                      isDone
                          ? Icons.check_rounded
                          : isActive
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2.w,
                      height: 32.h,
                      color: isDone
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE0E0E0),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14.sp,
                        color: isActive || isDone
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    if (isActive)
                      Text(
                        'Active now',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    if (!isLast) SizedBox(height: 18.h),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    ),
  );
}

Widget _buildBeforeAfterCard() {
  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before/After Photos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 14.h),
        _photoSlot('Before'),
        SizedBox(height: 12.h),
        _photoSlot('After'),
      ],
    ),
  );
}

Widget _photoSlot(String label) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey,
        ),
      ),
      SizedBox(height: 8.h),
      Container(
        width: double.infinity,
        height: 90.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Icon(
            Icons.camera_alt_outlined,
            color: Colors.grey,
            size: 30.sp,
          ),
        ),
      ),
    ],
  );
}

Widget _buildBottomButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return Container(
    color: Colors.white,
    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
    child: SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20.sp,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    ),
  );
}
