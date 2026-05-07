// lib/feature/auth/screens/password_reset_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../widget/auth/custom_back_button.dart';
import '../../widget/auth/custom_button.dart';
import '../../widget/auth/custom_text_field.dart';
import '../controller/auth_controller.dart';


// lib/feature/auth/screens/password_reset_screen.dart

class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AuthController.to;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),

                CustomBackButton(),

                SizedBox(height: 16.h),

                Center(
                  child: Image.asset('assets/images/auth/signin.png'),
                ),

                SizedBox(height: 20.h),

                Center(
                  child: Text(
                    "Password reset",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 24.sp,
                      color: const Color(0xFFF8C106),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // ── New Password ───────────────────────────────
                Obx(() => CustomTextField(
                  icon: Icons.lock_outline,
                  labelText: 'Enter your new password',
                  controller: c.newPasswordController,
                  obscureText: !c.isNewPasswordVisible.value,
                  suffixIcon: GestureDetector(
                    onTap: c.toggleNewPasswordVisibility,
                    child: Icon(
                      c.isNewPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFBDBDBD),
                      size: 20.sp,
                    ),
                  ),
                )),

                SizedBox(height: 16.h),

                // ── Re-Enter New Password ──────────────────────
                Obx(() => CustomTextField(
                  icon: Icons.lock_outline,
                  labelText: 'Re-Enter new password',
                  controller: c.reNewPasswordController,
                  obscureText: !c.isReNewPasswordVisible.value,
                  suffixIcon: GestureDetector(
                    onTap: c.toggleReNewPasswordVisibility,
                    child: Icon(
                      c.isReNewPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFBDBDBD),
                      size: 20.sp,
                    ),
                  ),
                )),

                SizedBox(height: 30.h),

                Obx(() => CustomButton(
                  text: c.isLoading.value ? 'Updating...' : 'Update Password',
                  onPressed: c.isLoading.value ? null : c.resetPassword,
                )),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}