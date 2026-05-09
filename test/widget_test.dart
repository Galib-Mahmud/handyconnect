
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/theme/app_theme.dart';
import 'package:handyConnect/route/app_route.dart';
import 'package:handyConnect/route/route_name.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());


}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: RouteName.chat,
          getPages: AppRoute.pages,
          // home: const SplashScreen(),
        );
      },
    );
  }
}