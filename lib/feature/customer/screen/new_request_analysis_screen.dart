// lib/features/home/views/new_request_analysis_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';


import '../../../route/route_name.dart';


class NewRequestAnalysisScreen extends StatefulWidget {
  const NewRequestAnalysisScreen({super.key});

  @override
  State<NewRequestAnalysisScreen> createState() =>
      _NewRequestAnalysisScreenState();
}

class _NewRequestAnalysisScreenState extends State<NewRequestAnalysisScreen> {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  late final int _requestId;
  Timer? _processTimer;
  Timer? _pollTimer;

  String _statusText = 'Analyzing Issue...';
  String _subText    = 'Our AI is diagnosing the problem';
  bool   _hasError   = false;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>?;
    _requestId = args?['request_id'] ?? 0;

    print('🔬 [ANALYSIS] Starting for request ID: $_requestId');

    // Wait 7 seconds then call /ai/process/
    _processTimer = Timer(const Duration(seconds: 5), _startAiProcess);
  }

  @override
  void dispose() {
    _processTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 3 — POST /ai/process/
  // ─────────────────────────────────────────────────────────────────
  Future<void> _startAiProcess() async {
    if (!mounted) return;

    try {
      print('🤖 [AI PROCESS] Calling /ai/process/ for request $_requestId...');

      setState(() {
        _statusText = 'AI Scanning...';
        _subText    = 'Detecting the issue in your images';
      });

      await _apiClient.post(
        ApiEndpoint.aiProcess,
        body: {'request_id': _requestId},
      );

      print('✅ [AI PROCESS] Scanning started');
    } catch (e) {
      // Non-fatal: still start polling regardless
      print('⚠️ [AI PROCESS] Error (still polling): $e');
    }

    // Start polling /ai/result/{id}/ every 3 seconds
    _startPolling();
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 4 — GET /ai/result/{id}/  poll every 3s
  // ─────────────────────────────────────────────────────────────────
  void _startPolling() {
    // Prothome 10 seconds wait korbe, tarpor proti 10s por por check korbe
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkResult();
    });
  }

  Future<void> _checkResult() async {
    if (!mounted) return;

    try {
      print('📊 [AI RESULT] Polling /ai/result/$_requestId/...');

      final response = await _apiClient.get(
        '${ApiEndpoint.aiResult}$_requestId/',
      );

      print('✅ [AI RESULT] $response');

      final bool   isFinished = response['is_finished'] ?? false;
      final String status     = (response['status'] ?? '').toString().toLowerCase();

      if (isFinished || status == 'completed') {
        _pollTimer?.cancel();
        if (!mounted) return;

        Get.offNamed(
             RouteName.confirmReq,
          arguments: {
            'request_id' : _requestId,
            'result_data': Map<String, dynamic>.from(response['data'] ?? {}),
          },
        );

      } else if (status == 'failed' || status == 'error') {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _hasError   = true;
            _statusText = 'Analysis Failed';
            _subText    = response['message']?.toString() ?? 'Something went wrong.';
          });
        }
      } else {
        // Still processing — update subtitle if server sends a message
        final msg = response['message']?.toString() ?? '';
        if (msg.isNotEmpty && mounted) {
          setState(() => _subText = msg);
        }
      }

    } catch (e) {
      print('⚠️ [AI RESULT] Poll error (will retry): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                      color: const Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFE0E0E0), thickness: 1, height: 1),

            // ── Centered Card ─────────────────────────────────────
            Expanded(
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon / Spinner
                      if (_hasError)
                        Icon(Icons.error_outline_rounded,
                            color: const Color(0xFFEF5350), size: 64.sp)
                      else
                        SizedBox(
                          width: 80.w,
                          height: 80.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 7,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFF8C106)),
                            backgroundColor: const Color(0xFFFFF3D0),
                          ),
                        ),

                      SizedBox(height: 32.h),

                      // Title
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: _hasError
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF212121),
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Subtitle
                      Text(
                        _subText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                      ),

                      // Go Back button on error
                      if (_hasError) ...[
                        SizedBox(height: 24.h),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 32.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8C106),
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Text(
                              'Go Back',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}