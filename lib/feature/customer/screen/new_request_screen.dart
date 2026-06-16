// lib/features/home/views/new_request_screen.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/home_dashboard_controller.dart';
import '../controller/new_request_controller.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController     = TextEditingController();
  final TextEditingController _zipController         = TextEditingController();
  final TextEditingController _phoneController       = TextEditingController();

  RequestController? _ctrl;
  int _requestId = 0;
  Map<String, dynamic> _serviceDetails = {};

  // ── Theme tokens ─────────────────────────────────────────────────
  static const _yellow    = Color(0xFFF8C106);
  static const _bg        = Color(0xFFF6F7F9);
  static const _ink       = Color(0xFF1A1D1F);
  static const _inkSoft   = Color(0xFF6F767E);
  static const _hint      = Color(0xFFB0B5BC);
  static const _fieldFill = Color(0xFFF4F5F7);

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(RequestController());

    final args = Get.arguments as Map<String, dynamic>?;

    _requestId = args?['requestId'] as int? ?? 0;
    _serviceDetails = (args?['serviceDetails'] is Map)
        ? Map<String, dynamic>.from(args!['serviceDetails'] as Map)
        : {};

    print('🆔 [NEW REQUEST] requestId: $_requestId');
    print('📦 [NEW REQUEST] serviceDetails: $_serviceDetails');

    if (_requestId == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar('Error', 'Invalid request. Please try again.');
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Parse service info from initialize response ───────────────────
  String get _serviceName {
    final details = _serviceDetails['service_details'];
    if (details is Map) {
      return (details['name_en'] ?? '').toString().isNotEmpty
          ? details['name_en'].toString()
          : (_serviceDetails['service_name'] ?? 'Service Request').toString();
    }
    return (_serviceDetails['service_name'] ?? 'Service Request').toString();
  }

  String get _serviceIcon {
    final details = _serviceDetails['service_details'];
    if (details is Map && (details['icon'] ?? '').toString().isNotEmpty) {
      return details['icon'].toString();
    }
    return (_serviceDetails['service_icon'] ?? '').toString();
  }

  String? get _serviceColorHex {
    final details = _serviceDetails['service_details'];
    if (details is Map && details['color'] != null) {
      return details['color'].toString();
    }
    return _serviceDetails['service_color']?.toString();
  }

  String get _priceRange {
    final details = _serviceDetails['service_details'];
    if (details is! Map) return '';
    final min = (details['min_price'] ?? '').toString();
    final max = (details['max_price'] ?? '').toString();
    if (min.isEmpty && max.isEmpty) return '';
    return '€$min – €$max';
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null || _requestId == 0) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _yellow),
        ),
      );
    }

    final ctrl = _ctrl!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Service info header ──────────────────────
                    _buildServiceHeader(),
                    SizedBox(height: 16.h),

                    // ── Problem ──────────────────────────────────
                    _buildCard(
                      title: 'Describe your problem',
                      subtitle: 'Tell us what went wrong',
                      child: _buildDescriptionField(),
                    ),
                    SizedBox(height: 16.h),

                    // ── Upload ───────────────────────────────────
                    _buildCard(
                      title: 'Upload photos',
                      subtitle: 'Optional · helps diagnose faster',
                      child: Column(
                        children: [
                          _buildUploadArea(ctrl),
                          Obx(() => ctrl.selectedImages.isNotEmpty
                              ? Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: _buildImagePreview(ctrl),
                          )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Location details ─────────────────────────
                    _buildCard(
                      title: 'Location',
                      subtitle: 'Where do you need help?',
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _addressController,
                            hintText: 'Street and house address',
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFE5484D),
                          ),
                          SizedBox(height: 12.h),
                          _buildInputField(
                            controller: _zipController,
                            hintText: 'Zip code',
                            icon: Icons.markunread_mailbox_rounded,
                            iconColor: _inkSoft,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _buildInputField(
                            controller: _phoneController,
                            hintText: 'Phone number (optional)',
                            icon: Icons.phone_rounded,
                            iconColor: _inkSoft,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // ── Preferences ──────────────────────────────
                    Obx(() => _buildCanCallTile(ctrl)),
                    SizedBox(height: 12.h),
                    Obx(() => _buildEmergencyTile(ctrl)),

                    SizedBox(height: 28.h),
                    Obx(() => _buildContinueButton(ctrl)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── App Bar ─────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 20.w, 12.h),
      child: Row(
        children: [
          _circleBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Get.back(),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Request',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'A few details to get you matched',
                style: TextStyle(fontSize: 12.sp, color: _inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _ink, size: 21.sp),
      ),
    );
  }

  // ───────────────────── Service Info Header ─────────────────────────
  Widget _buildServiceHeader() {
    final icon     = _serviceIcon;
    final colorHex = _serviceColorHex;
    final price    = _priceRange;

    Color iconBg = const Color(0xFFE0E0E0);
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hex = colorHex.replaceAll('#', '');
        iconBg = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    final bool isEmoji = icon.isNotEmpty &&
        icon.runes.any((r) => r > 0x00FF);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: isEmoji
                  ? Text(icon, style: TextStyle(fontSize: 26.sp))
                  : Image.asset(
                HomeController.assetFromString(icon),
                width: 28.w,
                height: 28.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
                if (price.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Estimated  $price',
                    style: TextStyle(fontSize: 12.sp, color: _inkSoft),
                  ),
                ],
              ],
            ),
          ),
          // Draft badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Draft',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: _yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Section Card ────────────────────────────────
  Widget _buildCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.sp, color: _inkSoft),
            ),
          ],
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  // ───────────────────── Description Field ───────────────────────────
  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      style: TextStyle(fontSize: 14.sp, color: _ink, height: 1.4),
      decoration: InputDecoration(
        hintText: 'e.g. The kitchen sink is leaking and water keeps dripping…',
        hintStyle: TextStyle(fontSize: 13.sp, color: _hint, height: 1.4),
        filled: true,
        fillColor: _fieldFill,
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(focused: true),
        contentPadding: EdgeInsets.all(16.w),
      ),
    );
  }

  // ───────────────────── Upload Area ─────────────────────────────────
  Widget _buildUploadArea(RequestController ctrl) {
    return GestureDetector(
      onTap: () => ctrl.pickImages(),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: _yellow,
          strokeWidth: 1.5,
          borderRadius: 16.r,
          dashWidth: 7,
          dashSpace: 5,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 28.h),
          child: Column(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo_rounded,
                    color: _yellow, size: 24.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Tap to capture or upload',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'JPG, PNG · max 5 images',
                style: TextStyle(fontSize: 11.sp, color: _inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── Image Preview ───────────────────────────────
  Widget _buildImagePreview(RequestController ctrl) {
    return SizedBox(
      height: 76.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ctrl.selectedImages.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(ctrl.selectedImages[index].path),
                  width: 76.w,
                  height: 76.w,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => ctrl.removeImage(index),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 14.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────── Input Field ─────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 14.sp, color: _ink),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13.sp, color: _hint),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14.w, right: 10.w),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _fieldFill,
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(focused: true),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
      ),
    );
  }

  OutlineInputBorder _fieldBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: focused ? _yellow : Colors.transparent,
        width: focused ? 1.5 : 1,
      ),
    );
  }

  // ───────────────────── Can Call Tile ───────────────────────────────
  Widget _buildCanCallTile(RequestController ctrl) {
    return _buildToggleTile(
      active: ctrl.canCall.value,
      activeColor: const Color(0xFF22C55E),
      onTap: () => ctrl.canCall.toggle(),
      icon: Icons.phone_in_talk_rounded,
      title: 'Allow provider to call me',
      badge: 'Recommended',
      badgeColor: const Color(0xFF22C55E),
      subtitle: 'Provider can call you directly to discuss the issue.',
    );
  }

  // ───────────────────── Emergency Tile ──────────────────────────────
  Widget _buildEmergencyTile(RequestController ctrl) {
    return _buildToggleTile(
      active: ctrl.isEmergency.value,
      activeColor: const Color(0xFFE5484D),
      onTap: () => ctrl.isEmergency.toggle(),
      icon: Icons.bolt_rounded,
      title: 'Mark as emergency',
      badge: '+€30',
      badgeColor: const Color(0xFFE5484D),
      subtitle: 'Priority placement and faster response from providers.',
    );
  }

  Widget _buildToggleTile({
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: activeColor.withOpacity(active ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: activeColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12.sp, color: _inkSoft, height: 1.35),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            _buildCheckbox(active, activeColor),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Checkbox ────────────────────────────────────
  Widget _buildCheckbox(bool checked, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: checked ? color : const Color(0xFFCDD1D6),
          width: 2,
        ),
        color: checked ? color : Colors.white,
      ),
      child: checked
          ? Icon(Icons.check_rounded, color: Colors.white, size: 15.sp)
          : null,
    );
  }

  // ───────────────────── Continue Button ─────────────────────────────
  Widget _buildContinueButton(RequestController ctrl) {
    final loading = ctrl.isLoading.value;
    return GestureDetector(
      onTap: loading
          ? null
          : () => ctrl.submitRequest(
        requestId  : _requestId,
        description: _descriptionController.text,
        address    : _addressController.text,
        zipCode    : _zipController.text,
        phoneNumber: _phoneController.text,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: loading ? _yellow.withOpacity(0.6) : _yellow,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: loading
              ? null
              : [
            BoxShadow(
              color: _yellow.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
            width: 22.w,
            height: 22.w,
            child: const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Diagnosis',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────── Dashed Border Painter ───────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rRect);
    final PathMetrics pathMetrics = path.computeMetrics();

    for (final PathMetric metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.borderRadius != borderRadius;
}