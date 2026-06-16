// lib/features/order/views/professional_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';
import '../controller/direct_hire_controller.dart';

class DirectHire extends StatelessWidget {
  const DirectHire({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final serviceId = args?['serviceId'] as int? ?? args?['service_id'] as int? ?? 0;
    final requestId = args?['requestId'] as int?
        ?? args?['request_id'] as int?
        ?? UserInfo.getRequestIdSync()
        ?? 0;

    final c = Get.put(DirectHireController(
      serviceId: serviceId,
      requestId: requestId,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Choose a Professional',
          style: TextStyle(
            color: const Color(0xFF1D2939),
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.toNamed(RouteName.customerinProgress),
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667085),
              ),
            ),
          ),
          Obx(() => c.isLoadingProviders.value
              ? Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1D2939)),
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
        // Loading state
        if (c.isLoadingProviders.value && c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFFF8C106)),
                SizedBox(height: 16.h),
                Text('Loading professionals…',
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFF9E9E9E))),
              ],
            ),
          );
        }

        // Error state
        if (c.errorMessage.value.isNotEmpty && c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48.sp, color: const Color(0xFFBDBDBD)),
                SizedBox(height: 12.h),
                Text(c.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFF9E9E9E))),
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

        // Empty state
        if (c.providers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search_rounded,
                    size: 52.sp, color: const Color(0xFFBDBDBD)),
                SizedBox(height: 12.h),
                Text('No professionals available.',
                    style: TextStyle(
                        fontSize: 14.sp, color: const Color(0xFF9E9E9E))),
              ],
            ),
          );
        }

        // Provider list
        return RefreshIndicator(
          color: const Color(0xFFF8C106),
          onRefresh: c.fetchProviders,
          child: ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: c.providers.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (_, index) => _ProviderCard(
              provider: c.providers[index],
              controller: c,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider Card
// ─────────────────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
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
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // ── Verified badge row ──────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: provider.isVerified
                          ? const Color(0xFF22C55E)
                          : Colors.grey[400],
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      provider.isVerified
                          ? 'Verified Professional'
                          : 'Professional',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D2939),
                      ),
                    ),
                    const Spacer(),
                    if (provider.isVerified)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '100% Trusted',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),

                // ── Profile row ────────────────────────────────
                Row(
                  children: [
                    // Avatar
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
                              color: Colors.grey, size: 28.sp)
                              : null,
                        ),
                        if (provider.isVerified)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12.w),

                    // Name + category + rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.fullName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D2939),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.work_outline_rounded,
                                  color: const Color(0xFF667085),
                                  size: 13.sp),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  provider.categoryName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF667085),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow → opens detail popup
                    GestureDetector(
                      onTap: () => _showProviderPopup(provider.id),
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8C106).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: const Color(0xFFF8C106),
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F4F7)),

          // ── Bottom: zip + invite button ───────────────────────
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zip Code',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF98A2B3))),
                    SizedBox(height: 2.h),
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
                Obx(() {
                  final blocked = controller.isLoadingProviders.value ||
                      controller.isSending.value;
                  return GestureDetector(
                    onTap: blocked
                        ? null
                        : () => controller.inviteProvider(
                        provider.id, provider.fullName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 11.h),
                      decoration: BoxDecoration(
                        color: blocked
                            ? const Color(0xFFF8C106).withOpacity(0.5)
                            : const Color(0xFFF8C106),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: blocked
                            ? null
                            : [
                          BoxShadow(
                            color: const Color(0xFFF8C106)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: blocked
                          ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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

  // ───────────────── Provider Detail Popup ───────────────────────────
  void _showProviderPopup(int providerId) async {
    // Show loading popup immediately
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32.w,
                height: 32.w,
                child: const CircularProgressIndicator(
                    color: Color(0xFFF8C106), strokeWidth: 3),
              ),
              SizedBox(height: 12.h),
              Text('Loading details…',
                  style:
                  TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E))),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final detail = await controller.fetchProviderDetails(providerId);

    // Dismiss loading
    if (Get.isDialogOpen ?? false) Get.back();

    if (detail == null) return;

    // Show detail popup
    Get.dialog(
      _ProviderDetailPopup(
        detail: detail,
        controller: controller,
      ),
      barrierColor: Colors.black38,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider Detail Popup
// ─────────────────────────────────────────────────────────────────────
class _ProviderDetailPopup extends StatelessWidget {
  const _ProviderDetailPopup({
    required this.detail,
    required this.controller,
  });

  final ProviderDetailModel detail;
  final DirectHireController controller;

  static const _ink     = Color(0xFF1D2939);
  static const _inkSoft = Color(0xFF667085);
  static const _yellow  = Color(0xFFF8C106);
  static const _green   = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 0.9.sw,
        constraints: BoxConstraints(maxHeight: 0.82.sh),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header with close button ────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 0),
              child: Row(
                children: [
                  Text(
                    'Professional Profile',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _inkSoft, size: 18.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // ── Scrollable body ─────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile header ───────────────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32.r,
                          backgroundColor: const Color(0xFFF2F4F7),
                          backgroundImage: detail.profilePhoto != null
                              ? NetworkImage(detail.profilePhoto!)
                              : null,
                          child: detail.profilePhoto == null
                              ? Icon(Icons.person,
                              color: Colors.grey, size: 32.sp)
                              : null,
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      detail.fullName,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  if (detail.isVerified) ...[
                                    SizedBox(width: 6.w),
                                    Icon(Icons.verified_rounded,
                                        color: _green, size: 18.sp),
                                  ],
                                ],
                              ),
                              if (detail.email.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  detail.email,
                                  style: TextStyle(
                                      fontSize: 12.sp, color: _inkSoft),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // ── Stats row ────────────────────────────────
                    Row(
                      children: [
                        _statChip(Icons.work_outline_rounded,
                            '${detail.jobsCount}', 'Jobs'),
                        SizedBox(width: 10.w),
                        _statChip(Icons.star_rounded,
                            detail.averageRating.toStringAsFixed(1), 'Rating'),
                        SizedBox(width: 10.w),
                        _statChip(Icons.rate_review_outlined,
                            '${detail.reviewCount}', 'Reviews'),
                        SizedBox(width: 10.w),
                        _statChip(Icons.my_location_rounded,
                            '${detail.radiusKm} km', 'Radius'),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // ── Bio ──────────────────────────────────────
                    if (detail.bio.isNotEmpty) ...[
                      Text('About',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      SizedBox(height: 6.h),
                      Text(detail.bio,
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: _inkSoft,
                              height: 1.4)),
                      SizedBox(height: 20.h),
                    ],

                    // ── Services ─────────────────────────────────
                    if (detail.services.isNotEmpty) ...[
                      Text('Services',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _uniqueServices()
                            .map((s) => _serviceChip(s))
                            .toList(),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // ── Rating breakdown ─────────────────────────
                    if (detail.ratingBreakdown.isNotEmpty) ...[
                      Text('Ratings',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      SizedBox(height: 8.h),
                      ...List.generate(5, (i) {
                        final star = (5 - i).toString();
                        final count =
                            detail.ratingBreakdown[star] ?? 0;
                        final total = detail.reviewCount > 0
                            ? detail.reviewCount
                            : 1;
                        return _ratingBar(star, count, total);
                      }),
                      SizedBox(height: 20.h),
                    ],

                    // ── Verification status ──────────────────────
                    if (detail.verificationStatus.isNotEmpty) ...[
                      Text('Verification',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      SizedBox(height: 8.h),
                      _verifyRow('Government ID',
                          detail.verificationStatus['government_id'] == true),
                      _verifyRow('Professional Certificate',
                          detail.verificationStatus['professional_certificate'] == true),
                      _verifyRow('Profile Photo',
                          detail.verificationStatus['profile_photo'] == true),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.shield_rounded,
                              color: _yellow, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'Trust Score: ${detail.verificationStatus['trust_score'] ?? 0}%',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: _yellow,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // ── Invite button ────────────────────────────
                    Obx(() {
                      final sending = controller.isSending.value;
                      return GestureDetector(
                        onTap: sending
                            ? null
                            : () {
                          Get.back(); // close popup
                          controller.inviteProvider(
                              detail.id, detail.fullName);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: sending
                                ? _yellow.withOpacity(0.5)
                                : _yellow,
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: sending
                                ? null
                                : [
                              BoxShadow(
                                color: _yellow.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: sending
                                ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child:
                              const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5),
                            )
                                : Text(
                              'Invite ${detail.fullName}',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat chip ──────────────────────────────────────────────────────
  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16.sp, color: _yellow),
            SizedBox(height: 4.h),
            Text(value,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
            Text(label,
                style: TextStyle(fontSize: 10.sp, color: _inkSoft)),
          ],
        ),
      ),
    );
  }

  // ── Service chip ───────────────────────────────────────────────────
  Widget _serviceChip(Map<String, dynamic> service) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        (service['name_en'] ?? '').toString(),
        style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: _ink),
      ),
    );
  }

  // ── Deduplicate services by name_en ────────────────────────────────
  List<Map<String, dynamic>> _uniqueServices() {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final s in detail.services) {
      final name = (s['name_en'] ?? '').toString();
      if (name.isNotEmpty && seen.add(name)) {
        unique.add(s);
      }
    }
    return unique;
  }

  // ── Rating bar row ─────────────────────────────────────────────────
  Widget _ratingBar(String star, int count, int total) {
    final fraction = count / total;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            child: Text(star,
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _inkSoft)),
          ),
          Icon(Icons.star_rounded,
              size: 12.sp, color: const Color(0xFFF8C106)),
          SizedBox(width: 8.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6.h,
                backgroundColor: const Color(0xFFF2F4F7),
                color: const Color(0xFFF8C106),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 20.w,
            child: Text('$count',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11.sp, color: _inkSoft)),
          ),
        ],
      ),
    );
  }

  // ── Verification row ───────────────────────────────────────────────
  Widget _verifyRow(String label, bool ok) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? _green : const Color(0xFFBDBDBD),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(label,
              style: TextStyle(fontSize: 13.sp, color: ok ? _ink : _inkSoft)),
        ],
      ),
    );
  }
}