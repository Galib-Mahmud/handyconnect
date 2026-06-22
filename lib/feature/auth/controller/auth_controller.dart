// lib/feature/auth/controllers/auth_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';
import '../../../route/route_name.dart';


class AuthController extends GetxController {
  static AuthController get to => Get.put(AuthController(), permanent: true);

  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  final RxBool isLoading = false.obs;

  // OTP flow type: 'register' | 'forgot_password'
  final RxString otpFlowType = 'register'.obs;

  // ─── OTP Timer ────────────────────────────────────────────────────
  final RxInt otpTimerSeconds = 60.obs;
  final RxBool canResend = false.obs;
  Timer? _otpTimer;

  // ─── Role Selection (signup screen) ──────────────────────────────
  final Rx<String?> selectedRole = Rx<String?>(null);

  // ─── SignUp Controllers ───────────────────────────────────────────
  final fullNameController = TextEditingController();
  final signUpEmailController = TextEditingController();
  final phoneController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpRePasswordController = TextEditingController();

  // ─── SignIn Controllers ───────────────────────────────────────────
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ─── Forgot Password Controllers ─────────────────────────────────
  final forgotEmailController = TextEditingController();

  // ─── Reset Password Controllers ───────────────────────────────────
  final newPasswordController = TextEditingController();
  final reNewPasswordController = TextEditingController();

  // ─── OTP Controllers ─────────────────────────────────────────────
  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());

  // ─── Password Visibility ─────────────────────────────────────────
  final RxBool isPasswordVisible = false.obs;
  final RxBool isSignUpPasswordVisible = false.obs;
  final RxBool isSignUpRePasswordVisible = false.obs;
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isReNewPasswordVisible = false.obs;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleSignUpPasswordVisibility() =>
      isSignUpPasswordVisible.value = !isSignUpPasswordVisible.value;
  void toggleSignUpRePasswordVisibility() =>
      isSignUpRePasswordVisible.value = !isSignUpRePasswordVisible.value;
  void toggleNewPasswordVisibility() =>
      isNewPasswordVisible.value = !isNewPasswordVisible.value;
  void toggleReNewPasswordVisibility() =>
      isReNewPasswordVisible.value = !isReNewPasswordVisible.value;

  // ─────────────────────────────────────────────────────────────────
  // OTP TIMER
  // ─────────────────────────────────────────────────────────────────
  void startOtpTimer() {
    _otpTimer?.cancel();
    otpTimerSeconds.value = 60;
    canResend.value = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimerSeconds.value > 0) {
        otpTimerSeconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  String get otpTimerLabel {
    final m = (otpTimerSeconds.value ~/ 60).toString().padLeft(1, '0');
    final s = (otpTimerSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─────────────────────────────────────────────────────────────────
  // ROLE SELECTION
  // ─────────────────────────────────────────────────────────────────
  void selectRole(String role) => selectedRole.value = role;

  // ─────────────────────────────────────────────────────────────────
  // ROLE + ONBOARDING BASED NAVIGATION
  // ─────────────────────────────────────────────────────────────────
  // Called after login AND from SplashController / main.dart on app open.
  //
  // Rules:
  //   CUSTOMER                           → customerHome (main)
  //   PROVIDER + onboarding APPROVED     → providerHome (main1)
  //   PROVIDER + onboarding NOT APPROVED → onboarding screen
  //   Unknown                            → signin (fallback)
  // ─────────────────────────────────────────────────────────────────
  static void navigateByRoleAndOnboarding({
    required String? role,
    required String? onboardingStatus,
  }) {
    if (role == 'CUSTOMER') {
      Get.offAllNamed(RouteName.main);
    } else if (role == 'PROVIDER') {
      if (onboardingStatus == 'APPROVED') {
        Get.offAllNamed(RouteName.main1);
      } else {
        // PENDING | UNDER_REVIEW | null → must complete onboarding
        Get.offAllNamed(RouteName.onboarding);
      }
    } else {
      Get.offAllNamed(RouteName.signin);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────────────────────────
  Future<void> register() async {
    if (fullNameController.text.trim().isEmpty ||
        signUpEmailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        signUpPasswordController.text.isEmpty ||
        signUpRePasswordController.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }
    if (selectedRole.value == null) {
      _showError('Please select your role (Provider or Customer)');
      return;
    }
    if (signUpPasswordController.text != signUpRePasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      await _apiClient.post(
        ApiEndpoint.register,
        body: {
          'full_name': fullNameController.text.trim(),
          'email': signUpEmailController.text.trim(),
          'phone_number': phoneController.text.trim(),
          'password': signUpPasswordController.text.trim(),
          're_password': signUpRePasswordController.text.trim(),
          'role': selectedRole.value,
        },
        requiresAuth: false,
      );
      await UserInfo.setUserEmail(signUpEmailController.text.trim());
      otpFlowType.value = 'register';
      _clearOtpFields();
      startOtpTimer();
      Get.toNamed(RouteName.otpVerification);
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      print('❌ Register error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // VERIFY OTP
  // ─────────────────────────────────────────────────────────────────
  Future<void> verifyOtp() async {
    if (otpFlowType.value == 'register') {
      await _verifyRegistrationOtp();
    } else {
      await _verifyForgotPasswordOtp();
    }
  }

  Future<void> _verifyRegistrationOtp() async {
    final code = _getOtpCode();
    if (code.length < 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }
    isLoading.value = true;
    try {
      final email = await UserInfo.getUserEmail();
      await _apiClient.post(
        ApiEndpoint.verifyOtp,
        body: {'email': email, 'code': code},
        requiresAuth: false,
      );
      _otpTimer?.cancel();
      Get.offAllNamed(RouteName.signin);
      _showSuccess('Account verified! Please sign in.');
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // RESEND OTP
  // ─────────────────────────────────────────────────────────────────
  Future<void> resendOtp() async {
    if (!canResend.value) return;
    if (otpFlowType.value == 'register') {
      await _resendRegistrationOtp();
    } else {
      await _resendForgotPasswordOtp();
    }
  }

  Future<void> _resendRegistrationOtp() async {
    final email = await UserInfo.getUserEmail();
    if (email == null) return;
    isLoading.value = true;
    try {
      await _apiClient.post(
        ApiEndpoint.register,
        body: {'email': email},
        requiresAuth: false,
      );
      startOtpTimer();
      _showSuccess('A new code has been sent to your email');
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGIN
  // POST /auth/login/
  // Response: refresh, access, user{ role, onboarding_status, ... }
  // ─────────────────────────────────────────────────────────────────
  Future<void> signIn() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showError('Please enter your email and password');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _apiClient.post(
        ApiEndpoint.login,
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
        requiresAuth: false,
      );

      if (response != null) {
        final user = response['user'] as Map<String, dynamic>?;

// ── is_verified string বা bool দুটোই handle করো ──────────
        final isVerifiedRaw = user?['is_verified'];
        final isVerified = isVerifiedRaw == true || isVerifiedRaw == 'true';

        // ── is_verified false হলে block করো ─────────────────────
        if (!isVerified) {
          Future.delayed(const Duration(milliseconds: 400), () {
            Get.rawSnackbar(
              duration: const Duration(seconds: 7),
              backgroundColor: Colors.black.withOpacity(0.75),
              messageText: const Text(
                '⏳ Your papers are now under admin review.\n\nOnce approved, you will be able to log in and access your account.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              borderRadius: 16,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              isDismissible: true,
              overlayBlur: 0,
            );
          });
          return; // token save করবে না, navigate করবে না
        }

        // ── বাকি সব আগের মতোই ───────────────────────────────────
        await UserInfo.setAccessToken(response['access'] ?? '');
        await UserInfo.setRefreshToken(response['refresh'] ?? '');
        await UserInfo.setFullName(user?['full_name'] ?? '');

        final role = user?['role']?.toString() ?? '';
        final onboardingStatus = user?['onboarding_status']?.toString() ?? '';

        if (role.isNotEmpty) await UserInfo.setRole(role);
        if (onboardingStatus.isNotEmpty) {
          await UserInfo.setOnboardingStatus(onboardingStatus);
        }

        await Future.delayed(Duration.zero);

        navigateByRoleAndOnboarding(
          role: role,
          onboardingStatus: onboardingStatus,
        );
      }
    } on UnauthorizedException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? 'Invalid email or password');
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      print('❌ Login error: $e');
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────────────────────────
  Future<void> forgotPassword() async {
    if (forgotEmailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }
    isLoading.value = true;
    try {
      await _apiClient.post(
        ApiEndpoint.forgotPassword,
        body: {'email': forgotEmailController.text.trim()},
        requiresAuth: false,
      );
      await UserInfo.setForgotPasswordEmail(forgotEmailController.text.trim());
      otpFlowType.value = 'forgot_password';
      _clearOtpFields();
      startOtpTimer();
      Get.toNamed(RouteName.otpVerification);
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _verifyForgotPasswordOtp() async {
    final code = _getOtpCode();
    if (code.length < 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }
    isLoading.value = true;
    try {
      final email = await UserInfo.getForgotPasswordEmail();
      await _apiClient.post(
        ApiEndpoint.verifyResetOtp,
        body: {'email': email, 'code': code},
        requiresAuth: false,
      );
      await UserInfo.setResetToken(code);
      _otpTimer?.cancel();
      Get.toNamed(RouteName.resetPass);
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _resendForgotPasswordOtp() async {
    final email = await UserInfo.getForgotPasswordEmail();
    if (email == null) return;
    isLoading.value = true;
    try {
      await _apiClient.post(
        ApiEndpoint.forgotPassword,
        body: {'email': email},
        requiresAuth: false,
      );
      startOtpTimer();
      _showSuccess('A new code has been sent to your email');
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // RESET PASSWORD
  // ─────────────────────────────────────────────────────────────────
  Future<void> resetPassword() async {
    if (newPasswordController.text.isEmpty ||
        reNewPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (newPasswordController.text != reNewPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (newPasswordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    isLoading.value = true;
    try {
      final email = await UserInfo.getForgotPasswordEmail();
      final code = await UserInfo.getResetToken();
      await _apiClient.post(
        ApiEndpoint.resetPassword,
        body: {
          'email': email,
          'code': code,
          'new_password': newPasswordController.text,
          're_new_password': reNewPasswordController.text,
        },
        requiresAuth: false,
      );
      await UserInfo.clearForgotPasswordEmail();
      await UserInfo.clearResetToken();
      _showSuccess('Password reset successfully. Please sign in.');
      Get.offAllNamed(RouteName.resetPassSucess);
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final refreshToken = await UserInfo.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          ApiEndpoint.logout,
          body: {'refresh': refreshToken},
          requiresAuth: true,
        );
      }
    } catch (e) {
      print('⚠️ Logout API error (ignored): $e');
    } finally {
      await UserInfo.clearAll();
      Get.offAllNamed(RouteName.signin);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // NAVIGATION HELPERS
  // ─────────────────────────────────────────────────────────────────
  void goToForgotPassword() => Get.toNamed(RouteName.forgetPass);
  void goToSignUp() => Get.toNamed(RouteName.signup);
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '274632425873-c9v234cl9dk6au17ier0n7hk99gqol7s.apps.googleusercontent.com',
    scopes: ['email', 'profile', 'openid'],
  );

  Future<void> continueWithGoogle() async {
    isLoading.value = true;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return; // user cancel করেছে
      }

      final auth = await googleUser.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) {
        _showError('Google token পাওয়া যায়নি। আবার চেষ্টা করো।');
        return;
      }

      final response = await _apiClient.post(
        ApiEndpoint.googleLogin,
        body: {'access_token': accessToken},
        requiresAuth: false,
      );

      _handleSocialResponse(response);
    } on HttpException catch (e) {
      _showError(_extractMessage(_tryParseBody(e.body)) ?? e.message);
    } catch (e) {
      print('❌ Google error: $e');
      _showError('Google sign-in fail হয়েছে।');
      await _googleSignIn.signOut();
    } finally {
      isLoading.value = false;
    }
  }
  void continueWithApple() => _showInfo('Apple sign-in coming soon');

  // ─────────────────────────────────────────────────────────────────
  // PARSERS
  // ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _tryParseBody(String? body) {
    if (body == null || body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  String? _extractMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    if (body.containsKey('detail')) return body['detail'].toString();
    if (body.containsKey('message')) return body['message'].toString();
    for (final entry in body.entries) {
      final val = entry.value;
      if (val is Map && val.containsKey('message')) return val['message'].toString();
      if (val is List && val.isNotEmpty) return val.first.toString();
      if (val is String) return val;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  String _getOtpCode() => otpControllers.map((c) => c.text).join('');
  void _clearOtpFields() { for (var c in otpControllers) c.clear(); }

  // ─────────────────────────────────────────────────────────────────
  // SNACKBARS
  // ─────────────────────────────────────────────────────────────────
  void _showError(String message) => Get.snackbar(
    "Error", message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.red.shade700,
    colorText: Colors.white,
    icon: const Icon(Icons.error_outline, color: Colors.white),
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 5),
  );

  void _showSuccess(String message) => Get.snackbar(
    "Success", message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.green.shade700,
    colorText: Colors.white,
    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 3),
  );

  void _showInfo(String message) => Get.snackbar(
    "Info", message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.blue.shade700,
    colorText: Colors.white,
    icon: const Icon(Icons.info_outline, color: Colors.white),
    margin: const EdgeInsets.all(12),
    borderRadius: 10,
    duration: const Duration(seconds: 4),
  );

  void _handleSocialResponse(dynamic response) {
    if (response == null) return;
    final user = response['user'] as Map<String, dynamic>?;

    UserInfo.setAccessToken(response['access'] ?? '');
    UserInfo.setRefreshToken(response['refresh'] ?? '');
    UserInfo.setFullName(user?['full_name'] ?? '');

    final role = user?['role']?.toString() ?? '';
    final onboardingStatus = user?['onboarding_status']?.toString() ?? '';

    if (role.isNotEmpty) UserInfo.setRole(role);
    if (onboardingStatus.isNotEmpty) UserInfo.setOnboardingStatus(onboardingStatus);

    navigateByRoleAndOnboarding(role: role, onboardingStatus: onboardingStatus);
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    super.onClose();
  }
}