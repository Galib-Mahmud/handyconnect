// lib/core/local_storage/user_info.dart

import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'UserInfo.init() must be called before use');
    return _prefs!;
  }

  // ======= Access Token ======= //
  static Future<void> setAccessToken(String token) async =>
      await _p.setString('access', token);
  static String? getAccessTokenSync() => _p.getString('access');
  static Future<String?> getAccessToken() async => _p.getString('access');

  // ======= Refresh Token ======= //
  static Future<void> setRefreshToken(String token) async =>
      await _p.setString('refresh', token);
  static Future<String?> getRefreshToken() async => _p.getString('refresh');

  // ======= Role ======= //
  // 'PROVIDER' | 'CUSTOMER'
  static Future<void> setRole(String role) async =>
      await _p.setString('role', role);
  static String? getRoleSync() => _p.getString('role');
  static Future<String?> getRole() async => _p.getString('role');

  // ======= Full Name ======= //
  static Future<void> setFullName(String name) async =>
      await _p.setString('full_name', name);
  static String? getFullNameSync() => _p.getString('full_name');
  static Future<String?> getFullName() async => _p.getString('full_name');

  // ======= Active Request ID ======= //
  // Save when customer creates / opens a service request.
  // Read from anywhere without passing via Get.arguments.
  // Clear on logout or when request is completed.
  static Future<void> setRequestId(int id) async =>
      await _p.setInt('request_id', id);
  static int? getRequestIdSync() => _p.getInt('request_id');
  static Future<int?> getRequestId() async => _p.getInt('request_id');
  static Future<void> clearRequestId() async => await _p.remove('request_id');

  // ======= Onboarding Status ======= //
  // Values: 'APPROVED' | 'UNDER_REVIEW' | 'PENDING' | null
  static Future<void> setOnboardingStatus(String status) async =>
      await _p.setString('onboarding_status', status);
  static String? getOnboardingStatusSync() =>
      _p.getString('onboarding_status');
  static Future<String?> getOnboardingStatus() async =>
      _p.getString('onboarding_status');

  // ======= isLoggedIn ======= //
  static Future<bool> isLoggedIn() async {
    final token = _p.getString('access');
    return token != null && token.isNotEmpty;
  }

  static bool isLoggedInSync() {
    final token = _p.getString('access');
    return token != null && token.isNotEmpty;
  }

  // ======= User Email (registration OTP flow) ======= //
  static Future<void> setUserEmail(String email) async =>
      await _p.setString('user_email', email);
  static Future<String?> getUserEmail() async => _p.getString('user_email');

  // ======= Forgot Password Email ======= //
  static Future<void> setForgotPasswordEmail(String email) async =>
      await _p.setString('forgot_password_email', email);
  static Future<String?> getForgotPasswordEmail() async =>
      _p.getString('forgot_password_email');
  static Future<void> clearForgotPasswordEmail() async =>
      await _p.remove('forgot_password_email');

  // ======= Reset Token ======= //
  static Future<void> setResetToken(String token) async =>
      await _p.setString('reset_token', token);
  static Future<String?> getResetToken() async => _p.getString('reset_token');
  static Future<void> clearResetToken() async =>
      await _p.remove('reset_token');

  // ======= Onboarding Completed (general) ======= //
  static Future<void> setOnboardingCompleted(bool value) async =>
      await _p.setBool('onboarding_completed', value);
  static Future<bool> getOnboardingCompleted() async =>
      _p.getBool('onboarding_completed') ?? false;

  // ======= Clear All (logout) ======= //
  static Future<void> clearAll() async => await _p.clear();
}