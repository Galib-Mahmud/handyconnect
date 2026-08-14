
import 'package:VonAbisZ/route/route_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../feature/auth/screen/forgot_password_screen.dart';
import '../feature/auth/screen/otp_verification_screen.dart';
import '../feature/auth/screen/pass_reset_screen.dart';
import '../feature/auth/screen/pass_reset_sucess_screen.dart';
import '../feature/auth/screen/sign_in_screen.dart';
import '../feature/auth/screen/sign_up_screen.dart';
import '../feature/customer/main_screen.dart';
import '../feature/customer/screen/application_sent_screen.dart';
import '../feature/customer/screen/confirm_request_screen.dart';
import '../feature/customer/screen/direct_hire_screen.dart';
import '../feature/customer/screen/home_dashboard_screen.dart';
import '../feature/customer/screen/customer_in_progress_screen.dart';
import '../feature/customer/screen/my_request_screen.dart';
import '../feature/customer/screen/new_request_analysis_screen.dart';
import '../feature/customer/screen/new_request_screen.dart';
import '../feature/customer/screen/notification_screen.dart';
import '../feature/customer/screen/profile_screen.dart';
import '../feature/customer/screen/recent_request_screen.dart';
import '../feature/customer/screen/save_address_screen.dart';
import '../feature/customer/screen/service_provider_screen.dart';
import '../feature/onboarding/screen/onboarding_screen.dart';
import '../feature/professional/main_screen_1.dart';
import '../feature/professional/screen/active_job_screen.dart';
import '../feature/professional/screen/earning_screen.dart';
import '../feature/professional/screen/job_request_screen.dart';
import '../feature/professional/screen/professional_home_screen.dart';
import '../feature/professional/screen/professional_profile_screen.dart';
import '../feature/professional/screen/subscription_screen.dart';
import '../feature/splash/screen/splash_screen.dart';


class AppRoute {
  static final List<GetPage> pages = [
    // ── Auth ─────────────────────────────────────────────────────
    GetPage(name: RouteName.splash,         page: () => SplashScreen()),
    GetPage(name: RouteName.signin,         page: () => SignInScreen()),
    GetPage(name: RouteName.signup,         page: () => SignUpScreen()),
    GetPage(name: RouteName.forgetPass,     page: () => ForgotPasswordScreen()),
    GetPage(name: RouteName.otpVerification,page: () => OtpVerificationScreen()),
    GetPage(name: RouteName.resetPass,      page: () => PasswordResetScreen()),
    GetPage(name: RouteName.resetPassSucess,page: () => PasswordResetSuccessScreen()),


    //Customer

    GetPage(name: RouteName.main,              page: () => MainScreen()),
    GetPage(name: RouteName.home,              page: () => HomeDashboardScreen()),
    GetPage(name: RouteName.myRequest,         page: () => MyRequest()),
    GetPage(name: RouteName.profile,           page: () => ProfileScreen()),
    GetPage(name: RouteName.recentRequest,     page: () => RecentRequestScreen()),
    GetPage(name: RouteName.savedAddresses,    page: () => SavedAddressesScreen()),
    GetPage(name: RouteName.notification,      page: () => NotificationsScreen()),
    GetPage(name: RouteName.newRequest,        page: () => NewRequestScreen()),
    GetPage(name: RouteName.newRequestAnalysis,page: () => NewRequestAnalysisScreen()),
    GetPage(name: RouteName.confirmReq,        page: () => ConfirmRequestScreen()),
    GetPage(name: RouteName.serviceProvider,   page: () => ServiceProviderScreen()),
    GetPage(name: RouteName.customerinProgress,        page: () => CustomerInProgressScreen()),
    GetPage(name: RouteName.applicationSent,   page: () => ApplicationSentScreen()),
    GetPage(name: RouteName.directHire,        page: () => DirectHire()),










    //Professional
    GetPage(name: RouteName.main1,                 page: () => MainScreen1()),
    GetPage(name: RouteName.professionalProfile,   page: () => ProfessionalProfileScreen()),
    GetPage(name: RouteName.professionalHome,      page: () => ProfessionalHomeScreen()),
    GetPage(name: RouteName.activejob,             page: () => ActiveJobScreen()),
    GetPage(name: RouteName.jobRequests,           page: () => JobRequestsScreen()),
    GetPage(name: RouteName.earning,               page: () => EarningsScreen()),
    GetPage(name: RouteName.subscription,          page: () => SubscriptionScreen()),
    GetPage(name: RouteName.onboarding,            page: () => Onboarding()),










    // // ── Customer ──────────────────────────────────────────────────
    // GetPage(name: RouteName.main,              page: () => MainScreen()),
    // GetPage(name: RouteName.home,              page: () => HomeDashboardScreen()),
    // GetPage(name: RouteName.myRequest,         page: () => MyRequest()),
    // GetPage(name: RouteName.profile,           page: () => ProfileScreen()),
    // GetPage(name: RouteName.savedAddresses,    page: () => SavedAddressesScreen()),
    // GetPage(name: RouteName.newRequest,        page: () => NewRequestScreen()),
    // GetPage(name: RouteName.newRequestAnalysis,page: () => NewRequestAnalysisScreen()),
    // GetPage(name: RouteName.newRequestScreen1, page: () => NewRequestScreen1()),
    // GetPage(name: RouteName.professional,      page: () => ProfessionalScreen()),
    // GetPage(name: RouteName.chat,              page: () => ProfessionalChatScreen()),
    // GetPage(name: RouteName.review,            page: () => ProfessionalChatScreen()),
    // GetPage(name: RouteName.location,          page: () => ScheduleConfirmationScreen()),
    // GetPage(name: RouteName.confirmReq,        page: () => ConfirmRequestScreen()),
    // GetPage(name: RouteName.close,             page: () => RequestClosedScreen()),
    // GetPage(name: RouteName.notification,      page: () => NotificationsScreen()),
    //
    //
    // // ── Professional ──────────────────────────────────────────────
    // GetPage(name: RouteName.main1,           page: () => MainScreen1()),
    // GetPage(name: RouteName.onboarding1,     page: () => Onboarding()),
    // GetPage(name: RouteName.onboardingFlow,  page: () => Onboarding()),
    // GetPage(name: RouteName.subscription,    page: () => SubscriptionScreen()),
    // GetPage(name: RouteName.professionalHome,page: () => ProfessionalHomeScreen()),
    // GetPage(name: RouteName.jobRequests,     page: () => JobRequestsScreen()),
    // GetPage(name: RouteName.activejob, page: () => ActiveJobScreen()),
    // GetPage(name: RouteName.profilepage,     page: () => ProfessionalProfileScreen()),
    // GetPage(name: RouteName.earning,         page: () => EarningsPage()),
    //
    // // ── Legacy Sohan screens (keep until migrated) ────────────────
    // GetPage(name: RouteName.homepage,   page: () => Homepage()),
    // GetPage(name: RouteName.jobrequest, page: () => JobRequestPage()),
    //




  ];
}