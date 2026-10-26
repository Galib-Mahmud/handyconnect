// lib/feature/language/controller/language_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String countryCode;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.countryCode,
  });
}

class LanguageController extends GetxController {
  final RxString selectedLanguage = 'en'.obs;

  final List<LanguageOption> options = const [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English (US)',
      flag: '🇺🇸',
      countryCode: 'US',
    ),
    LanguageOption(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch (DE)',
      flag: '🇩🇪',
      countryCode: 'DE',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    final saved = UserInfo.getLanguageCodeSync();
    selectedLanguage.value = (saved == 'de') ? 'de' : 'en';
  }

  Future<void> changeLanguage(String code) async {
    if (selectedLanguage.value == code) return;

    selectedLanguage.value = code;
    await UserInfo.setLanguageCode(code);

    final locale = code == 'de' ? const Locale('de', 'DE') : const Locale('en', 'US');
    await Get.updateLocale(locale);

    // Sync preferred language to backend if user is logged in
    final token = UserInfo.getAccessTokenSync();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient(baseUrl: ApiEndpoint.baseUrl).patch(
          ApiEndpoint.authMe,
          body: {
            'preferred_language': code,
            'language': code,
          },
          requiresAuth: true,
        );
        print('✅ [LANGUAGE] Synced language ($code) to backend /api/auth/me/');
      } catch (e) {
        print('⚠️ [LANGUAGE] Failed to sync language to backend: $e');
      }
    }

    Get.snackbar(
      code == 'de' ? 'Sprache aktualisiert' : 'Language Updated',
      code == 'de'
          ? 'Die App-Sprache wurde auf Deutsch geändert.'
          : 'App language has been changed to English.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFF8C106),
      colorText: Colors.black,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.black),
    );
  }
}
