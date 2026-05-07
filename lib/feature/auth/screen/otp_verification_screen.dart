import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/local_storage/user_info.dart';
import '../../widget/auth/custom_back_button.dart';
import '../../widget/auth/custom_button.dart';
import '../controller/auth_controller.dart';


class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AuthController.to;
    final screenHeight = MediaQuery.of(context).size.height;

    final focusNodes = List.generate(6, (_) => FocusNode());

    void onOtpChanged(String value, int index) {
      if (value.isNotEmpty && index < 5) {
        focusNodes[index + 1].requestFocus();
      }
    }

    void onKeyPressed(RawKeyEvent event, int index) {
      if (event is RawKeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.backspace &&
          c.otpControllers[index].text.isEmpty &&
          index > 0) {
        focusNodes[index - 1].requestFocus();
      }
    }

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
                        "Check your email",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 24.sp,
                          color: const Color(0xFFF8C106),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Obx(() {
                        final isRegister = c.otpFlowType.value == 'register';
                        return FutureBuilder<String?>(
                          future: isRegister
                              ? UserInfo.getUserEmail()
                              : UserInfo.getForgotPasswordEmail(),
                          builder: (context, snap) {
                            final email = snap.data ?? '...';
                            return Text(
                              "We sent a code to $email.\nEnter the 6-digit code from your email.",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45.w,
                      height: 50.h,
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) => onKeyPressed(event, index),
                        child: TextField(
                          controller: c.otpControllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.0,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: const BorderSide(
                                color: Color(0xFFF8C106),
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => onOtpChanged(value, index),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: 16.h),

                // Timer / Resend row
                // Obx(() => Center(
                //   child: c.canResend.value
                //       ? GestureDetector(
                //     onTap: c.resendOtp,
                //     child: Text(
                //       'Resend Code',
                //       style: TextStyle(
                //         fontFamily: "Inter",
                //         fontSize: 14.sp,
                //         color: const Color(0xFFF8C106),
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   )
                //       : Text(
                //     'Resend in ${c.otpTimerLabel}',
                //     style: TextStyle(
                //       fontFamily: "Inter",
                //       fontSize: 14.sp,
                //       color: Colors.grey,
                //     ),
                //   ),
                // )),

                SizedBox(height: 30.h),

                // Verify Code Button
                Obx(() => CustomButton(
                  text: c.isLoading.value ? 'Verifying...' : 'Verify Code',
                  onPressed: c.isLoading.value ? null : c.verifyOtp,
                )),

                SizedBox(height: 20.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Haven't got the email yet? ",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Obx(() => GestureDetector(
                      onTap: c.canResend.value ? c.resendOtp : null,
                      child: Text(
                        "Resend email",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 14.sp,
                          color: c.canResend.value
                              ? const Color(0xFFF8C106)
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
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