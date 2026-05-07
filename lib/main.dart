import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/route/app_route.dart';
import 'package:handyConnect/route/route_name.dart';
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

  final bool isLoggedIn        = await UserInfo.isLoggedIn();
  final String? role           = UserInfo.getRoleSync();
  final String? onboardingStatus = UserInfo.getOnboardingStatusSync();

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    role: role,
    onboardingStatus: onboardingStatus,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;
  final String? onboardingStatus;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.role,
    this.onboardingStatus,
  });

  String get _determineInitialRoute {
    if (!isLoggedIn) return RouteName.splash;

    if (role == 'CUSTOMER') return RouteName.main;

    if (role == 'PROVIDER') {
      return (onboardingStatus == 'APPROVED')
          ? RouteName.main1
          : RouteName.onboarding1;
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
          initialRoute: _determineInitialRoute,
          getPages: AppRoute.pages,
          defaultTransition: Transition.cupertino,

          // ✅ full: controller বন্ধ হলে memory থেকে সরিয়ে দেয়
          //    keepFactory ব্যবহার করলে deleted controller আবার recreate হয়
          //    যেটা তোমার HomeController বারবার delete/recreate করছিল
          smartManagement: SmartManagement.full,
        );
      },
    );
  }
}