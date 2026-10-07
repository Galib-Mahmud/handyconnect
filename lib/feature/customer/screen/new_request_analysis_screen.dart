// lib/features/home/views/new_request_analysis_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';



import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
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

  String _statusText = 'analyzing_issue'.tr;
  String _subText    = 'ai_diagnosing'.tr;
  bool   _hasError   = false;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>?;
    _requestId = args?['request_id'] ?? 0;

    print('🔬 [ANALYSIS] Starting for request ID: $_requestId');

    // Start AI analysis after brief delay for smooth transition
    _processTimer = Timer(const Duration(milliseconds: 600), _startAiProcess);
  }

  @override
  void dispose() {
    _processTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 3 — POST /services/requests/{id}/start-ai/
  // ─────────────────────────────────────────────────────────────────
  Future<void> _startAiProcess({bool isRetry = false}) async {
    if (!mounted) return;

    try {
      print('🤖 [AI PROCESS] Starting AI for request $_requestId (retry: $isRetry)...');

      setState(() {
        _hasError   = false;
        _statusText = 'ai_scanning'.tr;
        _subText    = 'ai_detecting'.tr;
      });

      await _apiClient.post(
        ApiEndpoint.startAi(_requestId),
        body: isRetry ? {'retry': true} : {},
      );

      print('✅ [AI PROCESS] Scanning started');
    } on ConflictException {
      print('ℹ️ [AI PROCESS] Analysis already in-flight (409), polling...');
    } on ThrottleException {
      print('⚠️ [AI PROCESS] Throttled (429)');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusText = 'Too Many Requests';
          _subText = 'Please wait a moment before trying again.';
        });
      }
      return;
    } on HttpException catch (e) {
      if (e.statusCode == 409) {
        print('ℹ️ [AI PROCESS] 409 in-flight, polling...');
      } else if (e.statusCode == 400) {
        final msg = e.message.toLowerCase();
        // If the request was already published/listed, redirect to sent screen smoothly
        if (msg.contains('only available before') || msg.contains('already') || msg.contains('listed')) {
          print('ℹ️ [AI PROCESS] Request is already listed. Navigating to sent screen.');
          if (mounted) {
            Get.offNamed(
              RouteName.applicationSent,
              arguments: {'request_id': _requestId},
            );
          }
          return;
        }
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusText = 'Analysis Error';
            _subText = e.message;
          });
        }
        return;
      }
    } catch (e) {
      print('⚠️ [AI PROCESS] Error (still polling): $e');
    }

    // Start polling /ai/result/{id}/
    _startPolling();
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 4 — GET /ai/result/{id}/  poll every 3s
  // ─────────────────────────────────────────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkResult();
    });
    // Check first result after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted && (_pollTimer?.isActive ?? false)) {
        _checkResult();
      }
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

        final Map<String, dynamic> resultData = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : Map<String, dynamic>.from(response is Map ? response : {});

        Get.offNamed(
          RouteName.confirmReq,
          arguments: {
            'request_id' : _requestId,
            'result_data': resultData,
          },
        );

      } else if (status == 'failed' || status == 'error') {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _hasError   = true;
            _statusText = 'analysis_failed'.tr;
            _subText    = response['message']?.toString() ?? 'something_went_wrong'.tr;
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
                    'new_request'.tr,
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

                      // Action buttons on error
                      if (_hasError) ...[
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _startAiProcess(isRetry: true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8C106),
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                                child: Text(
                                  'retry'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                                child: Text(
                                  'go_back'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121),
                                  ),
                                ),
                              ),
                            ),
                          ],
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