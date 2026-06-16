// lib/feature/professional/activejob/controller/active_job_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:handyConnect/route/route_name.dart';
import 'package:image_picker/image_picker.dart';



enum JobProgressStatus { pending, active, completed }

class JobProgressStep {
  final int number;
  final String label;
  final String? subtitle;
  final JobProgressStatus status;

  const JobProgressStep({
    required this.number,
    required this.label,
    this.subtitle,
    required this.status,
  });
}

class ActiveJobController extends GetxController {
  final ApiClient  _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);
  final ImagePicker _picker   = ImagePicker();
  // Job ID comes from Get.arguments — set when acceptRequest() navigates
  int get jobId => (Get.arguments?['jobId'] as int?) ?? 0;

  // ── My own full name — needed for chat "isSentByMe" logic ────────  ← ADD THIS
  String get myName => UserInfo.getFullNameSync() ?? '';

  final RxBool isActionLoading = false.obs;



  // ── Job info ──────────────────────────────────────────────────────
  final RxString jobStatus     = 'Confirmed'.obs;
  final RxString jobStatusCode = 'CONFIRMED'.obs;
  final RxString clientName    = ''.obs;
  final RxString clientAddress = ''.obs;
  final RxString clientImage   = ''.obs;
  final RxString serviceName   = ''.obs;
  final RxString serviceIcon   = ''.obs;
  final RxString description   = ''.obs;
  final RxBool markAsPriority  = false.obs;
  final RxBool noCallJustChat  = false.obs;

  // ── AI Cost ───────────────────────────────────────────────────────
  final RxString estPriceMin  = '0'.obs;
  final RxString estPriceMax  = '0'.obs;
  final RxString estCurrency  = 'EUR'.obs;

  // ── Timeline ──────────────────────────────────────────────────────
  final Rx<DateTime?> timeRequestReceived = Rx(null);
  final Rx<DateTime?> timeOnTheWay        = Rx(null);
  final Rx<DateTime?> timeInProgress      = Rx(null);
  final Rx<DateTime?> timeCompleted       = Rx(null);

  // ── Photos ────────────────────────────────────────────────────────
  final RxString billImagePath   = ''.obs;
  final RxString beforePhotoPath = ''.obs;
  final RxString afterPhotoPath  = ''.obs;

  File? get billImageFile   => billImagePath.value.isNotEmpty   ? File(billImagePath.value)   : null;
  File? get beforePhotoFile => beforePhotoPath.value.isNotEmpty ? File(beforePhotoPath.value) : null;
  File? get afterPhotoFile  => afterPhotoPath.value.isNotEmpty  ? File(afterPhotoPath.value)  : null;

  // ── Progress steps ────────────────────────────────────────────────
  final RxList<JobProgressStep> progressSteps = <JobProgressStep>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _loadFromArgs(args);
    _rebuildSteps();
    // ✅ Do NOT call respond/accept here — already done in JobRequestsController
  }

  void _loadFromArgs(Map<String, dynamic> args) {
    clientName.value    = _str(args['customer_name'], fallback: 'Customer');
    clientAddress.value = _str(args['address']);
    clientImage.value   = _str(args['customer_photo']);

    final sd      = _asMap(args['service_details']);
    final svcName = _str(args['service_name']);
    serviceName.value = svcName.isNotEmpty
        ? svcName
        : _str(sd['name_en'], fallback: 'Service');
    serviceIcon.value = _str(args['service_icon']).isNotEmpty
        ? _str(args['service_icon'])
        : _str(sd['icon']);

    description.value    = _str(args['description']);
    markAsPriority.value = args['mark_as_priority'] == true;
    noCallJustChat.value = args['no_call_just_chat'] == true;

    final aiCost = _asMap(args['ai_cost']);
    estPriceMin.value = aiCost['min']?.toString() ?? '0';
    estPriceMax.value = aiCost['max']?.toString() ?? '0';
    estCurrency.value = _str(aiCost['currency'], fallback: 'EUR');

    jobStatusCode.value = _str(args['status'],         fallback: 'CONFIRMED');
    jobStatus.value     = _str(args['status_display'], fallback: 'Confirmed');

    _applyTimeline(_asMap(args['timeline']));
  }

  // ─────────────────────────────────────────────────────────────────
  // POST /services/requests/{id}/advance-status/
  // body: { "status": "ON_THE_WAY" }
  // ─────────────────────────────────────────────────────────────────
  Future<void> markOnTheWay() async => await _advanceStatus('ON_THE_WAY');

  // ─────────────────────────────────────────────────────────────────
  // POST /services/requests/{id}/advance-status/
  // body: { "status": "IN_PROGRESS" }
  // ─────────────────────────────────────────────────────────────────
  Future<void> markInProgress() async => await _advanceStatus('IN_PROGRESS');

  Future<void> _advanceStatus(String code) async {
    isActionLoading.value = true;
    try {
      print('📤 [ADVANCE] id=$jobId status=$code');
      final res = await _apiClient.post(
        ApiEndpoint.proAdvanceStatus(jobId),
        body: {'status': code},
        requiresAuth: true,
      );

      // Server returns updated status + timeline
      final newCode    = (res?['status']         as String?) ?? code;
      final newDisplay = (res?['status_display'] as String?) ?? code;
      jobStatusCode.value = newCode;
      jobStatus.value     = newDisplay;

      if (res != null && res['timeline'] != null) {
        _applyTimeline(_asMap(res['timeline']));
      }
      _rebuildSteps();
      print('✅ [ADVANCE] → $newCode');
    } on HttpException catch (e) {
      _showError(e.message);
    } catch (e) {
      print('❌ [ADVANCE] $e');
      _showError('Something went wrong.');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // POST /services/requests/{id}/submit-bill/
  // Multipart: bill_image, before_photo, after_photo
  // ─────────────────────────────────────────────────────────────────
  Future<void> submitBill() async {
    print('🔍 [BILL] bill=${billImagePath.value}');
    print('🔍 [BILL] before=${beforePhotoPath.value}');
    print('🔍 [BILL] after=${afterPhotoPath.value}');

    if (billImageFile == null ||
        beforePhotoFile == null ||
        afterPhotoFile == null) {
      _showError('Please attach bill image, before photo, and after photo.');
      return;
    }

    // Verify files actually exist on disk
    final missing = <String>[];
    if (!await billImageFile!.exists()) missing.add('bill');
    if (!await beforePhotoFile!.exists()) missing.add('before');
    if (!await afterPhotoFile!.exists()) missing.add('after');
    if (missing.isNotEmpty) {
      print('❌ [BILL] Files not found on disk: $missing');
      _showError('Some images could not be found. Please re-select.');
      return;
    }

    isActionLoading.value = true;
    try {
      print('📤 [BILL] Uploading to id=$jobId');
      print('   endpoint: ${ApiEndpoint.proSubmitBill(jobId)}');

      final res = await _apiClient.multipart(
        ApiEndpoint.proSubmitBill(jobId),
        method: 'POST',
        fields: {},
        files: {
          'bill_image'  : billImageFile!,
          'before_photo': beforePhotoFile!,
          'after_photo' : afterPhotoFile!,
        },
        requiresAuth: true,
      );

      print('✅ [BILL] Response: $res');

      final newCode = (res?['status'] as String?) ?? 'COMPLETED';
      jobStatusCode.value = newCode;
      jobStatus.value = 'Completed';
      _rebuildSteps();

      Get.snackbar(
        'Done',
        (res?['message'] as String?) ?? 'Job marked as Completed.',
        backgroundColor: const Color(0xFF43A047),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    } on HttpException catch (e) {
      print('❌ [BILL] HttpException [${e.statusCode}]: ${e.message}');
      print('❌ [BILL] Body: ${e.body}');
      _showError(e.message);
    } catch (e) {
      print('❌ [BILL] Unknown error: $e');
      _showError('Failed to submit bill.');
    } finally {
      isActionLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIMARY BUTTON TAP — routes to correct API based on current status
  // ─────────────────────────────────────────────────────────────────
  Future<void> onBottomButtonTap() async {
    switch (jobStatusCode.value) {
      case 'PENDING':
      case 'CONFIRMED':
        await markOnTheWay();     // → POST advance-status ON_THE_WAY
        break;
      case 'ON_THE_WAY':
        await markInProgress();   // → POST advance-status IN_PROGRESS
        break;
      case 'IN_PROGRESS':
        await submitBill();       // → POST submit-bill multipart
        break;
      case 'COMPLETED':
        await UserInfo.clearRequestId();
        Get.offAllNamed(RouteName.main1);
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // OPEN CHAT
  // Passes requestId (from UserInfo), clientName, myName to ChatController
  // ─────────────────────────────────────────────────────────────────
  void openChat() {
    final requestId = UserInfo.getRequestIdSync() ?? jobId;
    final myName    = UserInfo.getFullNameSync() ?? '';

    Get.toNamed(
      RouteName.chat,                    // add to RouteName
      arguments: {
        'requestId'  : requestId,
        'clientName' : clientName.value,
        'jobLabel'   : 'Job #$requestId',
        'clientPhoto': clientImage.value,
        'myName'     : myName,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // IMAGE PICKERS
  // ─────────────────────────────────────────────────────────────────
  Future<void> pickBillImage()   async { final p = await _pick(); if (p != null) billImagePath.value   = p; }
  Future<void> pickBeforePhoto() async { final p = await _pick(); if (p != null) beforePhotoPath.value = p; }
  Future<void> pickAfterPhoto()  async { final p = await _pick(); if (p != null) afterPhotoPath.value  = p; }

  Future<String?> _pick() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      return f?.path;
    } catch (_) {
      _showError('Could not pick image.');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BUTTON STATE (label / icon / color)
  // ─────────────────────────────────────────────────────────────────
  String get bottomButtonLabel {
    switch (jobStatusCode.value) {
      case 'PENDING':
      case 'CONFIRMED':   return "I'm On The Way";
      case 'ON_THE_WAY':  return 'Start Job';
      case 'IN_PROGRESS': return 'Submit Bill';
      case 'COMPLETED':   return 'Back to Home';
      default:            return 'Next Step';
    }
  }

  IconData get bottomButtonIcon {
    switch (jobStatusCode.value) {
      case 'PENDING':
      case 'CONFIRMED':   return Icons.directions_car_outlined;
      case 'ON_THE_WAY':  return Icons.build_outlined;
      case 'IN_PROGRESS': return Icons.receipt_long_outlined;
      case 'COMPLETED':   return Icons.home_outlined;
      default:            return Icons.check_circle_outline;
    }
  }

  Color get bottomButtonColor {
    if (jobStatusCode.value == 'IN_PROGRESS') return const Color(0xFF4CAF50);
    return const Color(0xFFFFC107);
  }

  bool get showBeforeAfterCard =>
      jobStatusCode.value == 'IN_PROGRESS' || jobStatusCode.value == 'COMPLETED';
  bool get isCompleted => jobStatusCode.value == 'COMPLETED';

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  String _str(dynamic v, {String fallback = ''}) {
    if (v == null)              return fallback;
    if (v is String)            return v.isEmpty ? fallback : v;
    if (v is Map || v is List)  return fallback;
    return v.toString().isEmpty ? fallback : v.toString();
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  void _applyTimeline(Map<String, dynamic> tl) {
    timeRequestReceived.value = _parseDate(tl['request_received']);
    timeOnTheWay.value        = _parseDate(tl['on_the_way']);
    timeInProgress.value      = _parseDate(tl['in_progress']);
    timeCompleted.value       = _parseDate(tl['completed']);
  }

  DateTime? _parseDate(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}'
        ' · ${l.day.toString().padLeft(2,'0')}.${l.month.toString().padLeft(2,'0')}';
  }

  void _rebuildSteps() {
    const order = ['CONFIRMED', 'ON_THE_WAY', 'IN_PROGRESS', 'COMPLETED'];
    final code  = jobStatusCode.value == 'PENDING' ? 'CONFIRMED' : jobStatusCode.value;
    final curIdx = order.indexOf(code);

    JobProgressStatus stepStatus(String step) {
      final idx = order.indexOf(step);
      if (idx < curIdx) return JobProgressStatus.completed;
      if (idx == curIdx) return JobProgressStatus.active;
      return JobProgressStatus.pending;
    }

    progressSteps.assignAll([
      JobProgressStep(
        number: 1, label: 'Accepted',
        subtitle: timeRequestReceived.value != null ? _fmt(timeRequestReceived.value!) : null,
        status: JobProgressStatus.completed,
      ),
      JobProgressStep(
        number: 2, label: 'On The Way',
        subtitle: timeOnTheWay.value != null ? _fmt(timeOnTheWay.value!) : null,
        status: stepStatus('ON_THE_WAY'),
      ),
      JobProgressStep(
        number: 3, label: 'In Progress',
        subtitle: timeInProgress.value != null ? _fmt(timeInProgress.value!) : null,
        status: stepStatus('IN_PROGRESS'),
      ),
      JobProgressStep(
        number: 4, label: 'Completed',
        subtitle: timeCompleted.value != null ? _fmt(timeCompleted.value!) : null,
        status: stepStatus('COMPLETED'),
      ),
    ]);
  }

  void _showError(String msg) => Get.snackbar(
    'Error', msg,
    snackPosition  : SnackPosition.TOP,
    backgroundColor: Colors.red.shade700,
    colorText      : Colors.white,
    icon           : const Icon(Icons.error_outline, color: Colors.white),
    margin         : const EdgeInsets.all(12),
    borderRadius   : 10,
    duration       : const Duration(seconds: 4),
  );
}