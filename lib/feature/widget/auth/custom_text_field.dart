import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? icon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.obscureText = false,
    required this.controller,
    this.keyboardType,
    this.icon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(

          color: Color(0xFFFFFFFF).withOpacity(0.8),
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.all(5.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10.w),
            if (icon != null) ...[
              Icon(
                icon,
                color: Color(0xFF555555),
                size: 24.sp,
              ),
              SizedBox(width: 5.w),
            ],
            Expanded(
              child: TextField(
                controller: controller, // Added controller
                obscureText: obscureText, // Added obscureText
                keyboardType: keyboardType, // Added keyboardType
                style: TextStyle(fontSize: 16.sp),
                decoration: InputDecoration(

                  fillColor: Color(0xFFFFFFFF).withOpacity(0.4),
                  hintText: labelText,
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            // 👇 THIS IS YOUR FIX
            if (suffixIcon != null) ...[
              SizedBox(width: 6.w),
              suffixIcon!,
            ],
          ],
        ),
      ),
    );
  }
}