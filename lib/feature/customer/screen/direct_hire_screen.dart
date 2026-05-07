// lib/features/order/views/professional_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/direct_hire_controller.dart';

class DirectHire extends StatelessWidget {
  const DirectHire({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DirectHireController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Professional',
          style: TextStyle(
            color: const Color(0xFF1D2939),
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Obx(() => c.isLoadingProviders.value
              ? Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1D2939),
                ),
              ),
            ),
          )
              : IconButton(
            icon: Icon(Icons.refresh,
                color: const Color(0xFF1D2939), size: 22.sp),
            onPressed: c.fetchProviders,
          )),
        ],
      ),
      body: Obx(() {
        // ── STEP 1 loading — full screen spinner ──────────────────
        if (c.isLoadingProviders.value && c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFF8C106)),
                SizedBox(height: 16.h),
                Text(
                  'Loading professionals…',
                  style: TextStyle(
                      fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
          );
        }

        // ── Error ─────────────────────────────────────────────────
        if (c.errorMessage.value.isNotEmpty && c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48.sp, color: const Color(0xFFBDBDBD)),
                SizedBox(height: 12.h),
                Text(
                  c.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: c.fetchProviders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8C106),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text('Retry',
                      style:
                      TextStyle(fontSize: 14.sp, color: Colors.white)),
                ),
              ],
            ),
          );
        }

        // ── Empty ─────────────────────────────────────────────────
        if (c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search_rounded,
                    size: 52.sp, color: const Color(0xFFBDBDBD)),
                SizedBox(height: 12.h),
                Text(
                  'No professionals available.',
                  style: TextStyle(
                      fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
          );
        }

        // ── Provider list (STEP 1 complete) ───────────────────────
        return RefreshIndicator(
          color: const Color(0xFFF8C106),
          onRefresh: c.fetchProviders,
          child: ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: c.providers.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (_, index) => _ProfessionalCard(
              provider  : c.providers[index],
              controller: c,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Professional Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.provider,
    required this.controller,
  });

  final ProviderModel provider;
  final DirectHireController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // ── Section 1: Verified badge ──────────────────────────
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: provider.isVerified
                          ? const Color(0xFF00C853)
                          : Colors.grey[400],
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Verified Professional',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D2939),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '100% Trusted',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Section 2: Profile info ────────────────────
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26.r,
                          backgroundColor: const Color(0xFFF2F4F7),
                          backgroundImage: provider.profilePhoto != null
                              ? NetworkImage(provider.profilePhoto!)
                              : null,
                          child: provider.profilePhoto == null
                              ? Icon(Icons.person,
                              color: Colors.grey, size: 30.sp)
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
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
                            provider.fullName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D2939),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.water_drop,
                                  color: Colors.blue, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text(
                                provider.categoryName,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Icon(Icons.star_rounded,
                                  color: const Color(0xFFF8C106),
                                  size: 14.sp),
                              SizedBox(width: 2.w),
                              Text(
                                provider.rating,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFF8C106),
                      size: 32.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F4F7)),

          // ── Section 3: Zip code + Send Request button ──────────
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
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF98A2B3)),
                    ),
                    Text(
                      provider.zipCode ?? '—',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF8C106),
                      ),
                    ),
                  ],
                ),

                // ── Send Request button ────────────────────────────
                // Blocked while GET is loading OR POST is in flight
                Obx(() {
                  final blocked = controller.isLoadingProviders.value ||
                      controller.isSending.value;

                  return GestureDetector(
                    onTap: blocked
                        ? null
                        : () => controller.sendRequest(
                      provider.id,
                      provider.fullName,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: blocked
                            ? const Color(0xFFF8C106).withOpacity(0.5)
                            : const Color(0xFFF8C106),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: blocked
                          ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        'Send Request',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}