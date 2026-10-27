// lib/feature/auth/screens/sign_up_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../widget/auth/custom_back_button.dart';
import '../../widget/auth/custom_button.dart';
import '../../widget/auth/custom_text_field.dart';
import '../controller/auth_controller.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AuthController.to;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.h),

                // Back button
                CustomBackButton(),

                SizedBox(height: 20.h),
                SizedBox(height: 14.h),

                // // ── Continue with Apple ────────────────────────────
                // _buildSocialButton(
                //   onTap: c.continueWithApple,
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Icon(Icons.apple, size: 22.sp, color: Colors.black),
                //       SizedBox(width: 10.w),
                //       Text(
                //         'Continue with Apple',
                //         style: TextStyle(
                //           fontSize: 15.sp,
                //           fontWeight: FontWeight.w500,
                //           color: const Color(0xFF212121),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(height: 20.h),

                // Full Name TextField
                CustomTextField(
                  icon: Icons.person_outline,
                  labelText: 'enter_full_name'.tr,
                  controller: c.fullNameController,
                  keyboardType: TextInputType.name,
                ),

                SizedBox(height: 16.h),

                // Email TextField
                CustomTextField(
                  icon: Icons.email_outlined,
                  labelText: 'enter_email'.tr,
                  controller: c.signUpEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 16.h),

                // // Mobile Number TextField
                // CustomTextField(
                //   icon: Icons.phone_outlined,
                //   labelText: 'enter_phone_number'.tr,
                //   controller: c.phoneController,
                //   keyboardType: TextInputType.phone,
                // ),

                SizedBox(height: 16.h),

                // Password TextField
                // Password Field
                Obx(
                  () => CustomTextField(
                    icon: Icons.lock_outline,
                    labelText: 'enter_password'.tr,
                    controller: c.signUpPasswordController,
                    obscureText: !c.isSignUpPasswordVisible.value,
                    suffixIcon: GestureDetector(
                      onTap: c.toggleSignUpPasswordVisibility,
                      child: Icon(
                        c.isSignUpPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFBDBDBD),
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Re-Enter Password Field
                Obx(
                  () => CustomTextField(
                    icon: Icons.lock_outline,
                    labelText: 'confirm_password'.tr,
                    controller: c.signUpRePasswordController,
                    obscureText: !c.isSignUpRePasswordVisible.value,
                    suffixIcon: GestureDetector(
                      onTap: c.toggleSignUpRePasswordVisibility,
                      child: Icon(
                        c.isSignUpRePasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFBDBDBD),
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // ── Register As label ─────────────────────────────
                Text(
                  'select_role'.tr,
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF424242),
                  ),
                ),

                SizedBox(height: 12.h),

                // ── Role Selection ────────────────────────────────
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          label: 'role_provider'.tr,
                          icon: Icons.handyman_outlined,
                          isSelected: c.selectedRole.value == 'PROVIDER',
                          onTap: () => c.selectRole('PROVIDER'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _RoleCard(
                          label: 'role_customer'.tr,
                          icon: Icons.person_outline,
                          isSelected: c.selectedRole.value == 'CUSTOMER',
                          onTap: () => c.selectRole('CUSTOMER'),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // Sign Up Button
                Obx(
                  () => CustomButton(
                    text: c.isLoading.value ? 'please_wait'.tr : 'sign_up'.tr,
                    onPressed: c.isLoading.value ? null : () => c.register(),
                  ),
                ),

                SizedBox(height: 20.h),

                // Already have an account? Login Here
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'already_have_account'.tr,
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 15.sp,
                        color: Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'log_in'.tr,
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 16.sp,
                          color: const Color(0xFFF8C106),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role Card Widget ─────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50.h,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8C106) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 8.w),

            Text(
              label,
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 18.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSocialButton({
  required VoidCallback onTap,
  required Widget child,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 54.h,
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
