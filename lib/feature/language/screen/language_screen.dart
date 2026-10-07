// lib/feature/language/screen/language_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controller/language_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LanguageController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFF212121), size: 22.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'language'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.h),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Text ──────────────────────────────────────────
              Text(
                'select_language'.tr,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'choose_preferred_language'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 24.h),

              // ── Language Options Cards ─────────────────────────────
              Obx(() {
                final current = c.selectedLanguage.value;
                return Column(
                  children: c.options.map((option) {
                    final bool isSelected = current == option.code;
                    return _buildLanguageCard(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => c.changeLanguage(option.code),
                    );
                  }).toList(),
                );
              }),

              SizedBox(height: 24.h),

              // ── Information Card ───────────────────────────────────
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E7),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFFDE89C), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFFD49B00),
                      size: 22.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'language_note'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF7A5A00),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
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
    );
  }

  Widget _buildLanguageCard({
    required LanguageOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? const Color(0xFFF8C106) : const Color(0xFFEEEEEE),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFF8C106).withOpacity(0.12)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
            child: Row(
              children: [
                // Flag Container
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF8C106)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option.flag,
                      style: TextStyle(fontSize: 22.sp),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Name and Native Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name == 'English'
                            ? 'lang_english'.tr
                            : 'lang_german'.tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        option.name == 'English'
                            ? 'lang_english_sub'.tr
                            : 'lang_german_sub'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark / Radio Indicator
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFFF8C106) : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF8C106)
                          : const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
