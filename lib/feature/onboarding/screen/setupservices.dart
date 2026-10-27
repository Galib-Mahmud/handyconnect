// lib/feature/onboarding/screen/setupservices.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/onboarding_controller.dart';
import 'onboarding_screen.dart';

class Screen3SetupServices extends StatelessWidget {
  final VoidCallback onNext;
  const Screen3SetupServices({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingController.to;

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

            // ── Business Address ──────────────────────────────────
            Text(
              'Business Address',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
                color: kTextDark,
              ),
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
                      const Icon(Icons.location_on_outlined, color: kPrimary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h, horizontal: 12.w),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // ── Categories from API ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select categories',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: kTextDark,
                  ),
                ),
                Obx(() => Text(
                      '${c.selectedServiceIds.length} selected',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: c.selectedServiceIds.isNotEmpty
                            ? kPrimary
                            : kTextGrey,
                      ),
                    )),
              ],
            ),
            SizedBox(height: 12.h),

            Obx(() {
              if (c.isLoadingServices.value) {
                return SizedBox(
                  height: 120.h,
                  child: const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                );
              }

              if (c.availableServices.isEmpty) {
                return SizedBox(
                  height: 120.h,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load services.',
                            style: TextStyle(
                                color: kTextGrey, fontSize: 13.sp)),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () => c.fetchServices(),
                          child: Text(
                            'Tap to retry',
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 0.95,
                children: c.availableServices.map((service) {
                  final int id = (service['id'] as num).toInt();
                  final bool isGerman = Get.locale?.languageCode == 'de';
                  final String name = (isGerman &&
                          (service['name_de']?.toString().isNotEmpty ?? false))
                      ? service['name_de'].toString()
                      : (service['name_en'] ?? service['name_de'] ?? 'Service')
                          .toString();
                  final bool selected = c.isSelected(id);

                  return GestureDetector(
                    onTap: () => c.toggleService(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? kPrimary : kBorderGrey,
                          width: selected ? 2.w : 1.w,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        color: selected ? kPrimaryLight : Colors.white,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildServiceIcon(service, selected),
                          SizedBox(height: 6.h),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? kPrimary : kTextDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),

            SizedBox(height: 20.h),

            // ── Pricing toggle ────────────────────────────────────
            Text(
              'Pricing Preference',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
                color: kTextDark,
              ),
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
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                margin: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: c.isHourly.value
                                      ? kPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
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
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                margin: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: !c.isHourly.value
                                      ? kPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
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
                        padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Text('€',
                                  style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 6.w),
                              Text('Competitive',
                                  style: TextStyle(
                                      color: kTextDark,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                c.isHourly.value ? '/hour' : '/job',
                                style: TextStyle(
                                    color: kTextGrey, fontSize: 13.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: 20.h),

            // ── Service Area radius ───────────────────────────────
            Text(
              'Service Area',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
                color: kTextDark,
              ),
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
                          const Icon(Icons.location_on_outlined,
                              color: kPrimary, size: 20),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Radius: ${c.serviceRadius.value.toInt()} Km',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                'Coverage area from your location',
                                style: TextStyle(
                                    color: kTextGrey, fontSize: 12.sp),
                              ),
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
      bottomButton: Obx(() => PrimaryButton(
            label: 'Submit Application',
            isLoading: c.isLoading.value,
            onTap: onNext,
          )),
    );
  }

  Widget _buildServiceIcon(Map<String, dynamic> service, bool isSelected) {
    final String iconStr = (service['icon'] ?? '').toString();
    final String colorHex = (service['color'] ?? '').toString();
    Color? serviceColor;
    if (colorHex.startsWith('#') && colorHex.length == 7) {
      try {
        serviceColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
      } catch (_) {}
    }

    final Color activeColor =
        isSelected ? kPrimary : (serviceColor ?? const Color(0xFF212121));

    const iconMap = {
      'water_drop': Icons.water_drop_outlined,
      'bolt': Icons.bolt_outlined,
      'cleaning': Icons.cleaning_services_outlined,
      'carpentry': Icons.handyman_outlined,
      'palette': Icons.palette_outlined,
      'ac_unit': Icons.ac_unit_outlined,
      'local_shipping': Icons.local_shipping_outlined,
      'eco': Icons.eco_outlined,
      'wrench': Icons.build_outlined,
      'home': Icons.home_repair_service_outlined,
    };

    if (iconMap.containsKey(iconStr.toLowerCase())) {
      return Icon(iconMap[iconStr.toLowerCase()],
          size: 28.sp, color: activeColor);
    }

    if (iconStr.isNotEmpty && iconStr.runes.length <= 2) {
      return Text(iconStr, style: TextStyle(fontSize: 26.sp));
    }

    return Icon(Icons.handyman_outlined, size: 28.sp, color: activeColor);
  }
}