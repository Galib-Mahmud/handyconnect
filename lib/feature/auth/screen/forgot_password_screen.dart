// lib/feature/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/auth_controller.dart';
import '../../widget/auth/custom_back_button.dart';
import '../../widget/auth/custom_button.dart';
import '../../widget/auth/custom_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
                  child: Column(
                    children: [
                      Text(
                        "Forgot password",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 24.sp,
                          color: const Color(0xFFF8C106),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Please enter your email to reset the password",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                CustomTextField(
                  icon: Icons.email_outlined,
                  labelText: 'Enter Email Address',
                  controller: c.forgotEmailController,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 30.h),

                Obx(() => CustomButton(
                  text: c.isLoading.value ? 'Sending OTP...' : 'Get OTP',
                  onPressed:
                  c.isLoading.value ? null : c.forgotPassword,
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