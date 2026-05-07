import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBackButton extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  const CustomBackButton({
    super.key,
    this.backgroundColor = const Color(0xFFF8C106), // Teal color
    this.iconColor = Colors.white,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          color: iconColor,
          size: 20.sp,
        ),
      ),
    );
  }
}