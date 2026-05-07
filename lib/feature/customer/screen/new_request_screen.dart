import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/new_request_controller.dart';

class NewRequestScreen extends StatefulWidget {
  final int serviceId;
  const NewRequestScreen({super.key, this.serviceId = 1});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController     = TextEditingController();
  final TextEditingController _zipController         = TextEditingController();
  final TextEditingController _phoneController       = TextEditingController();

  late final RequestController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(RequestController());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            _buildAppBar(),
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFEEEEEE), thickness: 1, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),

                    _buildSectionTitle('Describe your Problem'),
                    SizedBox(height: 10.h),
                    _buildDescriptionField(),

                    SizedBox(height: 24.h),

                    _buildSectionTitle('Upload Files'),
                    SizedBox(height: 10.h),
                    _buildUploadArea(),
                    SizedBox(height: 12.h),

                    // ── Selected Images Preview ──────────────────
                    Obx(() => _ctrl.selectedImages.isNotEmpty
                        ? _buildImagePreview()
                        : const SizedBox.shrink()),

                    SizedBox(height: 24.h),

                    _buildSectionTitle('Address'),
                    SizedBox(height: 10.h),
                    _buildInputField(
                      controller: _addressController,
                      hintText: 'Street and House Address...',
                      icon: Icons.location_on,
                      iconColor: const Color(0xFFE53935),
                    ),

                    SizedBox(height: 24.h),

                    _buildSectionTitle('Zip Code'),
                    SizedBox(height: 10.h),
                    _buildInputField(
                      controller: _zipController,
                      hintText: '1234',
                      icon: Icons.flag,
                      iconColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.number,
                    ),

                    SizedBox(height: 24.h),

                    _buildSectionTitle('Phone Number'),
                    SizedBox(height: 10.h),
                    _buildInputField(
                      controller: _phoneController,
                      hintText: '+49 123 456 7890',
                      icon: Icons.phone,
                      iconColor: const Color(0xFF424242),
                      keyboardType: TextInputType.phone,
                    ),

                    SizedBox(height: 20.h),

                    // ── Can Call Card ────────────────────────────
                    Obx(() => _buildCanCallCard()),
                    SizedBox(height: 16.h),

                    // ── Emergency Card ───────────────────────────
                    Obx(() => _buildEmergencyCard()),
                    SizedBox(height: 24.h),

                    // ── Continue Button ──────────────────────────
                    Obx(() => _buildContinueButton()),
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

  // ───────────────────── App Bar ─────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
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
            'Service Request',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Section Title ───────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF212121),
      ),
    );
  }

  // ───────────────────── Description Field ───────────────────────────
  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tell us what you need help with..',
        hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFFBDBDBD)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFF8C106), width: 1.5),
        ),
        contentPadding: EdgeInsets.all(16.w),
      ),
      style: TextStyle(fontSize: 14.sp, color: const Color(0xFF212121)),
    );
  }

  // ───────────────────── Upload Area ─────────────────────────────────
  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: () => _ctrl.pickImages(),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFF8C106),
          strokeWidth: 1.5,
          borderRadius: 14.r,
          dashWidth: 8,
          dashSpace: 5,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Column(
            children: [
              Icon(Icons.cloud_upload_outlined,
                  color: const Color(0xFFF8C106), size: 32.sp),
              SizedBox(height: 10.h),
              Text(
                'Tap to capture or upload',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'JPG, PNG (max 5 images)',
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── Image Preview ───────────────────────────────
  Widget _buildImagePreview() {
    return SizedBox(
      height: 80.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ctrl.selectedImages.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.file(
                  File(_ctrl.selectedImages[index].path),
                  width: 80.w,
                  height: 80.w,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _ctrl.removeImage(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFFBDBDBD)),
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.w),
          child: Icon(icon, color: iconColor, size: 22.sp),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFF8C106), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
      ),
      style: TextStyle(fontSize: 14.sp, color: const Color(0xFF212121)),
    );
  }

  // ───────────────────── Can Call Card ───────────────────────────────
  Widget _buildCanCallCard() {
    return GestureDetector(
      onTap: () => _ctrl.canCall.toggle(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFBDBDBD)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckbox(_ctrl.canCall.value),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                      children: [
                        const TextSpan(text: 'Allow provider to call me '),
                        TextSpan(
                          text: '(Recommended)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Provider can call you directly to discuss the issue.',
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF757575)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Emergency Card ──────────────────────────────
  Widget _buildEmergencyCard() {
    return GestureDetector(
      onTap: () => _ctrl.isEmergency.toggle(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _ctrl.isEmergency.value
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFFFEBEE).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFEF5350)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckbox(_ctrl.isEmergency.value),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                      children: [
                        const TextSpan(text: 'Mark as Emergency Service '),
                        TextSpan(
                          text: '(+€30)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Get priority placement and faster response times from providers.',
                    style: TextStyle(
                        fontSize: 12.sp, color: const Color(0xFF757575)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Checkbox ────────────────────────────────────
  Widget _buildCheckbox(bool checked) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: checked ? const Color(0xFFF8C106) : const Color(0xFFBDBDBD),
          width: 2,
        ),
        color: checked ? const Color(0xFFF8C106) : Colors.white,
      ),
      child: checked
          ? Icon(Icons.check, color: Colors.white, size: 14.sp)
          : null,
    );
  }

  // ───────────────────── Continue Button ─────────────────────────────
  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _ctrl.isLoading.value
          ? null
          : () => _ctrl.submitRequest(
        serviceId: widget.serviceId,
        description: _descriptionController.text,
        address: _addressController.text,
        zipCode: _zipController.text,
        phoneNumber: _phoneController.text,
      ),
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: _ctrl.isLoading.value
              ? const Color(0xFFF8C106).withOpacity(0.6)
              : const Color(0xFFF8C106),
          borderRadius: BorderRadius.circular(27.r),
        ),
        child: Center(
          child: _ctrl.isLoading.value
              ? const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2)
              : Text(
            'Continue to Diagnosis',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}