
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/endpoint/api_client.dart';
import '../../../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';

class ConfirmRequestScreen extends StatefulWidget {
  const ConfirmRequestScreen({super.key});

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  late final int _requestId;
  late final Map<String, dynamic> _resultData;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final args  = Get.arguments as Map<String, dynamic>?;
    _requestId  = args?['request_id']  ?? 0;
    _resultData = Map<String, dynamic>.from(args?['result_data'] ?? {});
    print('📋 [CONFIRM] Request $_requestId | data: $_resultData');
  }

  // ── POST /services/requests/{id}/send-offer/ ──────────────────────
  Future<void> _submitRequest() async {
    setState(() => _isSending = true);
    try {
      final response = await _apiClient.post(
        ApiEndpoint.sendOffer(_requestId),
        body: {},
      );

      // ── Save request id for further use ──────────────────────────
      final savedId = response?['id'] ?? response?['request_id'] ?? _requestId;
      await UserInfo.setRequestId(savedId as int);
      print('✅ [CONFIRM] Request ID saved: $savedId');

      if (mounted) Get.toNamed(RouteName.applicationSent);

    } on HttpException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'Could not submit request. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Severity helpers ──────────────────────────────────────────────
  Color _severityColor(String s) {
    final u = s.toUpperCase();
    if (u.contains('HIGH'))   return const Color(0xFFEF5350);
    if (u.contains('MEDIUM')) return const Color(0xFFFFA726);
    if (u.contains('LOW'))    return const Color(0xFF4CAF50);
    return const Color(0xFF9E9E9E);
  }

  Color _severityBg(String s) {
    final u = s.toUpperCase();
    if (u.contains('HIGH'))   return const Color(0xFFFFEBEE);
    if (u.contains('MEDIUM')) return const Color(0xFFFFF3E0);
    if (u.contains('LOW'))    return const Color(0xFFE8F5E9);
    return const Color(0xFFF5F5F5);
  }

  @override
  Widget build(BuildContext context) {
    final issue    = _resultData['detected_issue']  as String? ?? '';
    final desc     = _resultData['description']     as String? ?? '';
    final severity = _resultData['severity']        as String? ?? '';
    final price    = _resultData['formatted_price'] as String? ?? '—';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // ── App Bar ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(Icons.arrow_back,
                        color: const Color(0xFF212121), size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'New Request',
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFEEEEEE), thickness: 1, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // ── Step Indicators ────────────────────────
                    _buildStepIndicators(),

                    SizedBox(height: 20.h),

                    // ── AI Diagnosis Card ──────────────────────
                    _buildDiagnosisCard(issue, desc, severity),

                    SizedBox(height: 16.h),

                    // ── Location & Time Card ───────────────────
                    _buildLocationTimeCard(),

                    SizedBox(height: 16.h),

                    // ── Payment Method Card ────────────────────
                    _buildPaymentCard(),

                    SizedBox(height: 20.h),

                    // ── Estimated Total ────────────────────────
                    _buildEstimatedTotal(price),

                    SizedBox(height: 20.h),

                    // ── Submit Button ──────────────────────────
                    GestureDetector(
                      onTap: _isSending ? null : _submitRequest,
                      child: Container(
                        width: double.infinity,
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: _isSending
                              ? const Color(0xFFF8C106).withOpacity(0.6)
                              : const Color(0xFFF8C106),
                          borderRadius: BorderRadius.circular(27.r),
                        ),
                        child: Center(
                          child: _isSending
                              ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                              : Text(
                            'Submit Request',
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Center(
                      child: Text(
                        'By submitting, you agree to our Terms of Service.',
                        style: TextStyle(
                            fontSize: 13.sp, color: const Color(0xFF9E9E9E)),
                      ),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Step Indicators ─────────────────────────────
  Widget _buildStepIndicators() {
    return Row(
      children: [
        _buildStep(number: '1', label: 'Details',   isActive: false, isCompleted: true),
        Expanded(
          child: Container(
              height: 1,
              margin: EdgeInsets.only(bottom: 16.h),
              color: const Color(0xFFE0E0E0)),
        ),
        _buildStep(number: '2', label: 'Diagnosis', isActive: false, isCompleted: true),
        Expanded(
          child: Container(
              height: 1,
              margin: EdgeInsets.only(bottom: 16.h),
              color: const Color(0xFFE0E0E0)),
        ),
        _buildStep(number: '3', label: 'Confirm',   isActive: true,  isCompleted: false),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bool filled = isActive || isCompleted;
    return Column(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF8C106)
                : isCompleted
                ? const Color(0xFFE8E8E8)
                : Colors.white,
            shape: BoxShape.circle,
            border: !filled
                ? Border.all(color: const Color(0xFFE0E0E0), width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Text(number,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF757575)))
                : Text(number,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF9E9E9E))),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color:
            isActive ? const Color(0xFF212121) : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  // ───────────────────── AI Diagnosis Card ───────────────────────────
  Widget _buildDiagnosisCard(String issue, String desc, String severity) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Icon(Icons.psychology_outlined,
                      color: const Color(0xFFF8C106), size: 18.sp),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'AI Diagnosis',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121)),
              ),
              const Spacer(),
              // Severity badge
              if (severity.isNotEmpty)
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _severityBg(severity),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _severityColor(severity)),
                  ),
                ),
            ],
          ),

          SizedBox(height: 14.h),
          Divider(color: const Color(0xFFF0F0F0), height: 1),
          SizedBox(height: 14.h),

          // Detected Issue
          if (issue.isNotEmpty) ...[
            Text('Detected Issue',
                style: TextStyle(
                    fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
            SizedBox(height: 4.h),
            Text(
              issue,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121)),
            ),
            SizedBox(height: 12.h),
          ],

          // Description
          if (desc.isNotEmpty) ...[
            Text('Description',
                style: TextStyle(
                    fontSize: 12.sp, color: const Color(0xFF9E9E9E))),
            SizedBox(height: 4.h),
            Text(
              desc,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF424242),
                  height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────── Location & Time Card ────────────────────────
  Widget _buildLocationTimeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location & Time',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121))),
          SizedBox(height: 16.h),

          // Address row
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: const Color(0xFFBDBDBD), size: 22.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Address',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF9E9E9E))),
                      SizedBox(height: 3.h),
                      Text('Dizengoff St 120, Tel Aviv',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212121))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text('Change',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF8C106))),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Schedule row
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFF8C106), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: const Color(0xFFF8C106), size: 20.sp),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF9E9E9E))),
                    SizedBox(height: 3.h),
                    Text('Immediate (ASAP)',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF8C106))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Payment Card ────────────────────────────────
  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121))),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Center(
                    child: Container(
                      width: 24.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D0D0),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text('•••• 4242',
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121))),
                const Spacer(),
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: const Color(0xFFF8C106), width: 2),
                  ),
                  child: Center(
                    child: Icon(Icons.check,
                        color: const Color(0xFFF8C106), size: 16.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Estimated Total ─────────────────────────────
  Widget _buildEstimatedTotal(String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Estimated Total',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9E9E))),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          ),
          child: Text(
            // Show AI price if available, fallback to static
            price != '—' && price.isNotEmpty ? price : '₪350',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF8C106)),
          ),
        ),
      ],
    );
  }
}