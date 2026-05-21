// lib/features/professional/job_requests/views/job_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/professional/screen/active_job_screen.dart';
import '../../../core/local_storage/user_info.dart';
import '../../chat/controller/chat_controller.dart';
import '../../chat/screen/chat_screen.dart';
import '../controller/job_request_controller.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(JobRequestsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _buildHeader(c),
            SizedBox(height: 12.h),

            // ── Scrollable Filter Chips ─────────────────────────────
            _buildFilterChips(c),
            SizedBox(height: 12.h),

            // ── Request List ────────────────────────────────────────
            Expanded(child: _buildRequestList(c)),
          ],
        ),
      ),
    );
  }

  // ── Header with Title & Refresh ───────────────────────────────────
  Widget _buildHeader(JobRequestsController c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, size: 22.sp, color: const Color(0xFF212121)),
          ),
          SizedBox(width: 14.w),
          Text(
            'Job Requests',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF212121),
            ),
          ),
          const Spacer(),
          // Refresh
          Obx(() => GestureDetector(
            onTap: c.isLoading.value ? null : c.refreshCurrent,
            child: Icon(
              c.isLoading.value ? Icons.hourglass_bottom : Icons.refresh,
              size: 22.sp,
              color: c.isLoading.value ? const Color(0xFF9E9E9E) : const Color(0xFF212121),
            ),
          )),
        ],
      ),
    );
  }

  // ── Scrollable Filter Chips ───────────────────────────────────────
  Widget _buildFilterChips(JobRequestsController c) {
    final filters = [
      {'type': RequestFilterType.active, 'label': 'Active', 'icon': Icons.check_circle_outline},
      {'type': RequestFilterType.private, 'label': 'Private', 'icon': Icons.lock_outline},
      {'type': RequestFilterType.emergency, 'label': 'Emergency', 'icon': Icons.warning_amber_rounded},
      {'type': RequestFilterType.newRequest, 'label': 'New', 'icon': Icons.new_releases},
    ];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final type = filter['type'] as RequestFilterType;
          final label = filter['label'] as String;
          final icon = filter['icon'] as IconData;

          return Obx(() {
            final isSelected = c.selectedFilter.value == type;
            return _FilterChip(
              label: label,
              icon: icon,
              isSelected: isSelected,
              onTap: () => c.changeFilter(type),
            );
          });
        },
      ),
    );
  }

  // ── Request List with Loading/Empty States ────────────────────────
  Widget _buildRequestList(JobRequestsController c) {
    return Obx(() {
      // Loading state (first load)
      if (c.isLoading.value && c.currentList.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF8C106)),
        );
      }

      // Empty state
      if (c.currentList.isEmpty) {
        return _buildEmptyState(c.selectedFilter.value);
      }

      // List with pull-to-refresh & pagination
      return NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!c.isLoading.value &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8 &&
              c.hasMore) {
            c.loadMore(c.selectedFilter.value);
          }
          return false;
        },
        child: RefreshIndicator(
          color: const Color(0xFFF8C106),
          onRefresh: c.refreshCurrent,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            itemCount: c.currentList.length + (c.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (_, index) {
              // Pagination loader at end
              if (index == c.currentList.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFFF8C106),
                      ),
                    ),
                  ),
                );
              }

              final request = c.currentList[index];
              return _RequestCard(
                request: request,
                filterType: c.selectedFilter.value,
                onAccept: () => c.acceptRequest(request.id),
                onDecline: () => c.declineRequest(request.id),
              );
            },
          ),
        ),
      );
    });
  }

  // ── Empty State per Filter ────────────────────────────────────────
  Widget _buildEmptyState(RequestFilterType type) {
    final config = {
      RequestFilterType.active: {'msg': 'No active requests', 'icon': Icons.work_outline},
      RequestFilterType.private: {'msg': 'No private requests', 'icon': Icons.lock_outline},
      RequestFilterType.emergency: {'msg': 'No emergency requests', 'icon': Icons.warning_amber},
      RequestFilterType.newRequest: {'msg': 'No new requests', 'icon': Icons.new_releases},
    }[type]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(config['icon'] as IconData, size: 64.sp, color: const Color(0xFFBDBDBD)),
          SizedBox(height: 16.h),
          Text(
            config['msg'] as String,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Filter Chip Widget ─────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8C106) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFF8C106) : const Color(0xFFE0E0E0),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFFF8C106).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF212121),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card Widget ─────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final RequestFilterType filterType;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.filterType,
    required this.onAccept,
    required this.onDecline,
  });

  bool get _isPending => request.status.toUpperCase() == 'PENDING';
  bool get _isDimmed => request.isSold || ['COMPLETED', 'IN_PROGRESS'].contains(request.status.toUpperCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isDimmed ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: request.markAsPriority && !_isDimmed
            ? Border.all(color: const Color(0xFFEF5350).withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientRow(),
          SizedBox(height: 14.h),
          _buildIssueBox(),
          SizedBox(height: 12.h),
          _buildAddressRow(),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          SizedBox(height: 12.h),
          _buildBottomRow(),
        ],
      ),
    );
  }

  // ── Client Row (Avatar + Name + Chat Button) ──────────────────────
  Widget _buildClientRow() {
    return Row(
      children: [
        // Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: request.customerPhoto?.isNotEmpty == true
              ? Image.network(
            request.customerPhoto!,
            width: 44.w,
            height: 44.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(),
          )
              : _avatarFallback(),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.customerName,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _isDimmed ? const Color(0xFF9E9E9E) : const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12.sp, color: const Color(0xFF9E9E9E)),
                  SizedBox(width: 4.w),
                  Text(
                    request.formattedDate,
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                  ),
                  // ── Chat Button (Phone Hidden Logic) ───────────────
                  if (request.noCallJustChat) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        // Create the controller and navigate
                        Get.to(
                              () => ProfessionalChatScreen(
                            controller: ProfessionalChatController(
                              requestId  : request.id,
                              clientName : request.customerName,
                              jobLabel   : 'Job #${request.id}',
                              clientPhoto: request.customerPhoto ?? '',
                              myFullName : UserInfo.getFullNameSync() ?? '',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 12.sp, color: const Color(0xFF1565C0)),
                          SizedBox(width: 3.w),
                          Text('Chat only',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF1565C0))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Priority Badge + Icon
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (request.markAsPriority)
              Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF5350),
                  ),
                ),
              ),
            Image.asset(
              request.iconAsset,
              width: 28.w,
              height: 28.w,
              color: _isDimmed ? const Color(0xFFBDBDBD) : null,
              colorBlendMode: _isDimmed ? BlendMode.saturation : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8C106),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Center(
        child: Text(
          request.customerName.isNotEmpty ? request.customerName[0].toUpperCase() : 'C',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  // ── Issue Box (Service + Description + Cost) ──────────────────────
  Widget _buildIssueBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _isDimmed ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.displayName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _isDimmed ? const Color(0xFF9E9E9E) : const Color(0xFF212121),
            ),
          ),
          if (request.description.isNotEmpty) ...[
            SizedBox(height: 5.h),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: _isDimmed ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                height: 1.4,
              ),
            ),
            SizedBox(height: 6.h),
          ],
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Est. Cost  ',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                TextSpan(
                  text: request.formattedAiCost,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _isDimmed ? const Color(0xFFBDBDBD) : const Color(0xFFF8C106),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Address Row ───────────────────────────────────────────────────
  Widget _buildAddressRow() {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 14.sp, color: const Color(0xFF9E9E9E)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            request.address,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
          ),
        ),
      ],
    );
  }

  // ── Bottom Row (Zip + Action Buttons) ─────────────────────────────
  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Zip Code + Applicants
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zip Code', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
            SizedBox(height: 3.h),
            Text(
              request.zipCode,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: _isDimmed ? const Color(0xFF9E9E9E) : const Color(0xFFF8C106),
              ),
            ),
            if (request.applicationCount > 0) ...[
              SizedBox(height: 3.h),
              Text(
                '${request.applicationCount} applied',
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
              ),
            ],
          ],
        ),
        // Action Buttons based on status & filter
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Sold overlay handled in Stack parent if needed
    if (request.isSold) {
      return _badge(label: 'Sold', color: const Color(0xFF757575));
    }

    final status = request.status.toUpperCase();

    // Completed / In Progress - Show status badge
    if (['COMPLETED'].contains(status)) {
      return _buildStatusBadge(label: 'Completed', color: const Color(0xFF43A047));
    }
    if (['IN_PROGRESS', 'ACCEPTED', 'ON_THE_WAY'].contains(status)) {
      return _buildStatusBadge(label: request.statusDisplay, color: const Color(0xFF1565C0));
    }

    // Pending - Show Accept/Decline (only for New/Private/Emergency filters)
    if (_isPending && filterType != RequestFilterType.active) {
      return Row(
        children: [
          GestureDetector(
            onTap: onDecline,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFE53935), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, color: const Color(0xFFE53935), size: 14.sp),
                  SizedBox(width: 4.w),
                  Text('Decline', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFFE53935))),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onAccept,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.white, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text('Accept', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Active filter - Show "View Details" or status
    return GestureDetector(
      onTap: () => onAccept(), // Navigate to ActiveJobScreen
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8C106),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'View Details',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusBadge({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.check, color: color, size: 14.sp),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── Open Chat (Phone Hidden Logic) ────────────────────────────────
  void _openChat(BuildContext context) {
    if (request.id <= 0) {
      Get.snackbar('Error', 'Request ID not available', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.to(
          () => ProfessionalChatScreen(
        controller: ProfessionalChatController(
          requestId: request.id,
          clientName: request.customerName,
          jobLabel: 'Job #${request.id}',
          clientPhoto: request.customerPhoto ?? '',
          myFullName: UserInfo.getFullNameSync() ?? '',
        ),
      ),
    );
  }
}