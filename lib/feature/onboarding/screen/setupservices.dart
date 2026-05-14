// lib/feature/professional/screen/Onboardingpages/setupservices.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/onboarding/controller/onboarding_controller.dart';
import 'package:handyConnect/feature/onboarding/screen/onboarding_screen.dart';



class Screen3SetupServices extends StatelessWidget {
  final VoidCallback onNext;
  const Screen3SetupServices({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingController.to;

    final List<Map<String, dynamic>> categories = [
      {'name': 'Plumbing', 'icon': '💧'},
      {'name': 'Electrical', 'icon': '⚡'},
      {'name': 'Ac & HVAC', 'icon': '❄️'},
      {'name': 'Painting', 'icon': '🎨'},
      {'name': 'Moving', 'icon': '🚚'},
      {'name': 'Gardening', 'icon': '🌿'},
    ];

    return BaseScreen(
      step: 2,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Up your services',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tell us what service you offer',
              style: TextStyle(fontSize: 14.sp, color: kTextGrey),
            ),
            SizedBox(height: 16.h),

            // Business Address field
            Text(
              'Business Address',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: kTextDark),
            ),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorderGrey),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextField(
                controller: c.businessAddressController,
                decoration: InputDecoration(
                  hintText: 'e.g. Berlin, 123 Main St',
                  hintStyle: TextStyle(color: kTextGrey, fontSize: 14.sp),
                  prefixIcon:
                  Icon(Icons.location_on_outlined, color: kPrimary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h, horizontal: 12.w),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Categories
            Text(
              'Select categories',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: kTextDark),
            ),
            SizedBox(height: 12.h),
            Obx(() => GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.1,
              children: categories.map((cat) {
                final isSelected =
                c.selectedCategories.contains(cat['name']);
                return GestureDetector(
                  onTap: () =>
                      c.toggleCategory(cat['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? kPrimary : kBorderGrey,
                        width: isSelected ? 2.w : 1.w,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      color: isSelected ? kPrimaryLight : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat['icon'] as String,
                          style: TextStyle(fontSize: 28.sp),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color:
                            isSelected ? kPrimary : kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
            SizedBox(height: 20.h),

            // Pricing toggle
            Text(
              'Pricing',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: kTextDark),
            ),
            SizedBox(height: 10.h),
            Obx(() => Container(
              decoration: BoxDecoration(
                border: Border.all(color: kBorderGrey),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => c.isHourly.value = true,
                          child: Container(
                            padding:
                            EdgeInsets.symmetric(vertical: 10.h),
                            margin: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: c.isHourly.value
                                  ? kPrimary
                                  : Colors.transparent,
                              borderRadius:
                              BorderRadius.circular(8.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Hourly Rate',
                              style: TextStyle(
                                color: c.isHourly.value
                                    ? Colors.white
                                    : kTextGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => c.isHourly.value = false,
                          child: Container(
                            padding:
                            EdgeInsets.symmetric(vertical: 10.h),
                            margin: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: !c.isHourly.value
                                  ? kPrimary
                                  : Colors.transparent,
                              borderRadius:
                              BorderRadius.circular(8.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Price Range',
                              style: TextStyle(
                                color: !c.isHourly.value
                                    ? Colors.white
                                    : kTextGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Text('\$',
                              style: TextStyle(
                                  color: kPrimary, fontSize: 16.sp)),
                          SizedBox(width: 4.w),
                          Text('0.00',
                              style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(
                              c.isHourly.value ? '/hour' : '/job',
                              style: TextStyle(
                                  color: kTextGrey, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: 20.h),

            // Service Area radius
            Text(
              'Service Area',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: kTextDark),
            ),
            SizedBox(height: 12.h),
            Obx(() => Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderGrey),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: kPrimary, size: 18.sp),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radius: ${c.serviceRadius.value.toInt()} Km',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp),
                          ),
                          Text('Coverage area from your location',
                              style: TextStyle(
                                  color: kTextGrey, fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: c.serviceRadius.value,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    activeColor: kPrimary,
                    inactiveColor: kBorderGrey,
                    onChanged: (v) => c.serviceRadius.value = v,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5 km',
                          style: TextStyle(
                              fontSize: 11.sp, color: kTextGrey)),
                      Text('25 km',
                          style: TextStyle(
                              fontSize: 11.sp, color: kTextGrey)),
                      Text('50 km',
                          style: TextStyle(
                              fontSize: 11.sp, color: kTextGrey)),
                    ],
                  ),
                ],
              ),
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
      // Button shows spinner while API is in-flight
      bottomButton: Obx(() => PrimaryButton(
        label: 'Submit Application',
        isLoading: c.isLoading.value,
        onTap: onNext, // onNext calls submitOnboarding() in Onboarding widget
      )),
    );
  }
}