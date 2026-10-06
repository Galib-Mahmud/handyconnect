import 'package:VonAbisZ/route/app_route.dart';
import 'package:VonAbisZ/route/route_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/localization/app_translations.dart';
import 'core/local_storage/user_info.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.config(enableLog: true);

  await UserInfo.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final bool isLoggedIn          = await UserInfo.isLoggedIn();
  final String? role             = UserInfo.getRoleSync();
  final String? onboardingStatus = UserInfo.getOnboardingStatusSync();
  final String initialLang       = UserInfo.getLanguageCodeSync();

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    role: role,
    onboardingStatus: onboardingStatus,
    initialLang: initialLang,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  final String? onboardingStatus;
  final String initialLang;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.role,
    this.onboardingStatus,
    required this.initialLang,
  });

  String get _determineInitialRoute {
    if (!isLoggedIn) return RouteName.splash;

    if (role == 'CUSTOMER') return RouteName.main;

    if (role == 'PROVIDER') {
      return (onboardingStatus == 'APPROVED')
          ? RouteName.main1
          : RouteName.onboarding;
    }

    return RouteName.signin;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: initialLang == 'de'
              ? const Locale('de', 'DE')
              : const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          initialRoute: _determineInitialRoute,
          getPages: AppRoute.pages,
          defaultTransition: Transition.cupertino,
          smartManagement: SmartManagement.full,
        );
      },
    );
  }
}