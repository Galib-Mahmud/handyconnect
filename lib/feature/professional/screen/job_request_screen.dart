// lib/features/professional/job_requests/views/job_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/professional/controller/job_request_controller.dart';



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
            SizedBox(height: 16.h),

            Expanded(
              child: Obx(() {
                if (c.isLoading.value &&
                    c.activeAndCompleted.isEmpty &&
                    c.newLeads.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF8C106)),
                  );
                }

                if (c.activeAndCompleted.isEmpty && c.newLeads.isEmpty) {
                  return _buildEmpty();
                }

                return RefreshIndicator(
                  color: const Color(0xFFF8C106),
                  onRefresh: () => c.fetchRequests(),
                  child: ListView(
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    children: [
                      if (c.activeAndCompleted.isNotEmpty) ...[
                        _buildSectionLabel('Active & Completed'),
                        SizedBox(height: 10.h),
                        ...c.activeAndCompleted.map((r) => Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: _JobRequestCard(
                            request: r,
                            status:
                            JobRequestsController.statusFromString(
                                r['status'] ?? ''),
                            onAccept: () => c.acceptRequest(r['id']),
                            onDecline: () => c.declineRequest(r['id']),
                          ),
                        )),
                        SizedBox(height: 8.h),
                      ],

                      if (c.newLeads.isNotEmpty) ...[
                        _buildSectionLabel('New Leads'),
                        SizedBox(height: 10.h),
                        ...c.newLeads.map((r) => Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: _JobRequestCard(
                            request: r,
                            status:
                            JobRequestsController.statusFromString(
                                r['status'] ?? ''),
                            onAccept: () => c.acceptRequest(r['id']),
                            onDecline: () => c.declineRequest(r['id']),
                          ),
                        )),
                      ],

                      SizedBox(height: 20.h),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF9E9E9E),
      ),
    );
  }

  Widget _buildHeader(JobRequestsController c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back,
                size: 22.sp, color: const Color(0xFF212121)),
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
          Obx(() => Container(
            width: 30.w,
            height: 30.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${c.totalCount}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF8C106),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 60.sp, color: const Color(0xFFBDBDBD)),
          SizedBox(height: 12.h),
          Text(
            'No job requests at the moment.',
            style:
            TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Job Request Card
// ══════════════════════════════════════════════════════════════════

class _JobRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final JobStatus status;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _JobRequestCard({
    required this.request,
    required this.status,
    required this.onAccept,
    required this.onDecline,
  });

  bool get _isDimmed =>
      status == JobStatus.completed || status == JobStatus.inProcess;

  // ── Safe string helper ────────────────────────────────────────────
  /// Reads any dynamic field as a String. Never casts — avoids the
  /// "_Map is not a subtype of String?" crash when JSON has nested objects.
  String _s(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? fallback : value;
    if (value is Map || value is List) return fallback; // never stringify maps
    return value.toString();
  }

  // ── Field accessors ───────────────────────────────────────────────
  String get _clientName  => _s(request['customer_name'], fallback: 'Customer');
  String get _timeAgo     => _s(request['formatted_date']);
  String get _address     => _s(request['address']);
  String get _zipCode     => _s(request['zip_code'], fallback: '—');
  String get _customerPhoto => _s(request['customer_photo']);

  /// ai_cost comes from the API as { "min": 160, "max": 380, "currency": "EUR" }
  /// — NEVER cast it to String? directly.
  String get _aiCost => _formatAiCost(request['ai_cost']);

  static String _formatAiCost(dynamic aiCost) {
    if (aiCost == null) return '—';
    if (aiCost is String) return aiCost.isNotEmpty ? aiCost : '—';
    if (aiCost is Map) {
      final min      = aiCost['min'];
      final max      = aiCost['max'];
      final currency = aiCost['currency'] ?? '';
      if (min != null && max != null) return '$currency $min – $max';
      if (min != null) return '$currency $min';
      if (max != null) return '$currency $max';
    }
    return '—';
  }

  String get _issueTitle {
    // service_name is often "" — fall back to service_details.name_en
    final svcName = _s(request['service_name']);
    if (svcName.isNotEmpty) return svcName;
    final details = request['service_details'];
    if (details is Map) return _s(details['name_en'], fallback: 'Service Request');
    return 'Service Request';
  }

  String get _description {
    final d = _s(request['description']);
    return d.isNotEmpty ? d : '—';
  }

  String get _assetPath =>
      JobRequestsController.assetFromIcon(_s(request['service_icon']));

  bool get _isSold     => request['is_sold'] == true;
  bool get _isPriority => request['mark_as_priority'] == true;
  bool get _noChatOnly => request['no_call_just_chat'] == true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _isDimmed ? const Color(0xFFF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: _isPriority && !_isDimmed && !_isSold
                ? Border.all(
                color: const Color(0xFFEF5350).withOpacity(0.4),
                width: 1.5)
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
        ),

        if (_isSold)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF474747),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Lead Already Sold',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Client Row ────────────────────────────────────────────────────
  Widget _buildClientRow() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: _customerPhoto.isNotEmpty
              ? ColorFiltered(
            colorFilter: _isDimmed
                ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ])
                : const ColorFilter.mode(
                Colors.transparent, BlendMode.color),
            child: Image.network(
              _customerPhoto,
              width: 44.w,
              height: 44.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAvatarFallback(),
            ),
          )
              : _buildAvatarFallback(),
        ),
        SizedBox(width: 12.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _clientName,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _isDimmed
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12.sp, color: const Color(0xFF9E9E9E)),
                  SizedBox(width: 4.w),
                  Text(
                    _timeAgo,
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                  ),
                  if (_noChatOnly) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.chat_bubble_outline,
                        size: 12.sp, color: const Color(0xFF1565C0)),
                    SizedBox(width: 3.w),
                    Text('Chat only',
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF1565C0))),
                  ],
                ],
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isPriority)
              Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Priority',
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF5350)),
                ),
              ),
            Image.asset(
              _assetPath,
              width: 28.w,
              height: 28.w,
              fit: BoxFit.contain,
              color: _isDimmed ? const Color(0xFFBDBDBD) : null,
              colorBlendMode: _isDimmed ? BlendMode.saturation : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8C106),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Center(
        child: Text(
          _clientName.isNotEmpty ? _clientName[0].toUpperCase() : 'C',
          style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      ),
    );
  }

  // ── Issue Box ─────────────────────────────────────────────────────
  Widget _buildIssueBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color:
        _isDimmed ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _issueTitle,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _isDimmed
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFF212121),
            ),
          ),
          SizedBox(height: 5.h),

          if (_description != '—') ...[
            Text(
              _description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: _isDimmed
                    ? const Color(0xFFBDBDBD)
                    : const Color(0xFF757575),
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
                    color: _isDimmed
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                TextSpan(
                  text: _aiCost,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _isDimmed
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFFF8C106),
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
        Icon(Icons.location_on_outlined,
            size: 14.sp, color: const Color(0xFF9E9E9E)),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            _address,
            overflow: TextOverflow.ellipsis,
            style:
            TextStyle(fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
          ),
        ),
      ],
    );
  }

  // ── Bottom Row ────────────────────────────────────────────────────
  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zip Code',
                style: TextStyle(
                    fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
            SizedBox(height: 3.h),
            Text(
              _zipCode,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: _isDimmed
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFFF8C106),
              ),
            ),
          ],
        ),
        if (status == JobStatus.pending && !_isSold) _buildPendingButtons(),
        if (status == JobStatus.completed)
          _buildStatusBadge(
              label: 'Completed', color: const Color(0xFF43A047)),
        if (status == JobStatus.inProcess)
          _buildStatusBadge(
              label: 'In Process', color: const Color(0xFF1565C0)),
      ],
    );
  }

  // ── Pending Buttons ───────────────────────────────────────────────
  Widget _buildPendingButtons() {
    return Row(
      children: [
        GestureDetector(
          onTap: onDecline,
          child: Container(
            padding:
            EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border:
              Border.all(color: const Color(0xFFE53935), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.close,
                    color: const Color(0xFFE53935), size: 14.sp),
                SizedBox(width: 6.w),
                Text('Decline',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935))),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: onAccept,
          child: Container(
            padding:
            EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.check, color: Colors.white, size: 14.sp),
                SizedBox(width: 6.w),
                Text('Accept',
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Badge ──────────────────────────────────────────────────
  Widget _buildStatusBadge(
      {required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.check, color: color, size: 14.sp),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}