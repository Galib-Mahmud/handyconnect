

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../widget/auth/custom_text_field.dart';
import '../controller/auth_controller.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AuthController.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),

              // ── Logo illustration ──────────────────────────────
              _buildLogo(),
              SizedBox(height: 48.h),

              // ── Continue with Google ───────────────────────────
              _buildSocialButton(
                onTap: c.continueWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleIcon(),
                    SizedBox(width: 12.w),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // ── Continue with Apple ────────────────────────────
              _buildSocialButton(
                onTap: c.continueWithApple,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, size: 22.sp, color: Colors.black),
                    SizedBox(width: 10.w),
                    Text(
                      'Continue with Apple',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // ── Email field ────────────────────────────────────
              CustomTextField(
                icon: Icons.email_outlined,
                labelText: 'Enter Email Address',
                controller: c.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 14.h),

              // ── Password field ─────────────────────────────────
              Obx(() => CustomTextField(
                icon: Icons.lock_outline_rounded,
                labelText: 'Enter Password',
                controller: c.passwordController,
                obscureText: !c.isPasswordVisible.value,
                suffixIcon: GestureDetector(
                  onTap: c.togglePasswordVisibility,
                  child: Icon(
                    c.isPasswordVisible.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFFBDBDBD),
                    size: 20.sp,
                  ),
                ),
              )),
              SizedBox(height: 20.h),

              // ── Forgot Password ────────────────────────────────
              GestureDetector(
                onTap: c.goToForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // ── Sign In button ─────────────────────────────────
              Obx(() => GestureDetector(
                onTap: c.isLoading.value ? null : c.signIn,
                child: Container(
                  width: double.infinity,
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: c.isLoading.value
                        ? const Color(0xFFF8C106).withOpacity(0.6)
                        : const Color(0xFFF8C106),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  alignment: Alignment.center,
                  child: c.isLoading.value
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
              SizedBox(height: 28.h),

              // ── Sign Up link ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                        fontSize: 15.sp, color: const Color(0xFF9E9E9E)),
                  ),
                  GestureDetector(
                    onTap: c.goToSignUp,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF8C106),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/auth/signin.png',
      width: 120.w,
      height: 120.w,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSocialButton(
      {required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF212121)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(fontSize: 14.sp, color: const Color(0xFFBDBDBD)),
          prefixIcon:
          Icon(icon, color: const Color(0xFF9E9E9E), size: 20.sp),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: const BorderSide(
              color: Color(0xFFFFC107),
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        ),
      ),
    );
  }
}

// ─────────────────── Google Icon ───────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/devicon_google.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}