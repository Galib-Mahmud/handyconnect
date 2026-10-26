// lib/core/endpoint/api_endpoint.dart

class ApiEndpoint {
  static const String serverUrl = 'https://api.vonabisz.de';
  static const String baseUrl = '$serverUrl/api';

  // ─── Protected Media URL Helper ────────────────────────────────────
  /// Converts a relative media path (e.g. "/media/providers/...") to a full URL.
  /// Backend serves protected media at GET /media/{path} with Bearer auth.
  static String mediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    return '$serverUrl$clean';
  }

  // ─── WebSocket Helpers ─────────────────────────────────────────────
  static String _wsBase() {
    return serverUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  static String chatWebSocket(int id) => '${_wsBase()}/ws/chat/$id/';
  static String trackingWebSocket(int id) => '${_wsBase()}/ws/tracking/$id/';

  // ─── Shared Auth & Account ─────────────────────────────────────────
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String verifyOtp = '/auth/verify-otp/';
  static const String googleLogin = '/auth/google/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String verifyResetOtp = '/auth/verify-reset-otp/';
  static const String resetPassword = '/auth/reset-password/';
  static const String refresh = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String authMe = '/auth/me/';
  static const String profile = '/auth/me/';
  static const String deleteAccount = '/services/delete-account/';

  // ─── Customer: Home / Catalog ──────────────────────────────────────
  static const String customerHomepage = '/services/requests/customer/homepage/';
  static const String provider = '/services/providers/';
  static String providerDetails(int id) => '/services/providers/$id/';

  // ─── Customer: Create a Request ────────────────────────────────────
  static const String initializeRequest = '/services/requests/initialize/';
  static const String uploadMedia = '/services/media/upload/';
  static String requestDetails(int id) => '/services/requests/$id/';
  static const String createRequest = '/services/requests/';
  static String startAi(int requestId) => '/services/requests/$requestId/start-ai/';
  static String aiResult(int id) => '/ai/result/$id/';
  static const String aiResultBase = '/ai/result/';
  static const String aiResultLegacy = '/ai/result/';

  // ─── Customer: My Requests Lifecycle ───────────────────────────────
  static const String customerRequests = '/services/requests/?page_size=50';
  static const String recentRequests = '/services/requests/?page_size=50';
  static const String allCustomerRequests = '/services/requests/?page_size=50';
  static const String requests = '/services/requests/';
  static const String allRequests = '/services/requests/';
  static String interestedProviders(int id) => '/services/requests/$id/interested-providers/';
  static String providersForRequest(int id) => '/services/providers/?request_id=$id&page_size=50';
  static String inviteProvider(int id) => '/services/providers/$id/invite/';
  static String hireProvider(int id) => '/services/requests/$id/hire-provider/';
  static String submitReview(int id) => '/services/requests/$id/submit-review/';
  static String customerConfirmBill(int id) => '/services/requests/$id/customer-confirm-bill/';
  static String closeJob(int id) => '/services/requests/$id/close-job/';
  static String cancelRequest(int id) => '/services/requests/$id/cancel/';
  static String sendOffer(int requestId) => '/services/requests/$requestId/send-offer/';

  // ─── Customer: Addresses, Support, Notifications, Chat ─────────────
  static const String addresses = '/services/addresses/';
  static String addressDetail(int id) => '/services/addresses/$id/';
  static const String support = '/services/support/';
  static const String notifications = '/services/notifications/';
  static const String notificationsMarkAllRead = '/services/notifications/mark-all-read/';
  static String notificationMarkRead(int id) => '/services/notifications/$id/mark-read/';
  static String chatMessages(int id) => '/services/requests/$id/messages/';

  // ─── Provider: Onboarding / Subscription / Catalog ─────────────────
  static const String providerOnboarding = '/pro/onboarding/';
  static const String submitForReview = '/pro/onboarding/submit-for-review/';
  static const String providerOnboardingStatus = '/auth/provider/onboarding/status/';
  static const String activateSubscription = '/pro/subscription/activate/';
  static const String servicesList = '/services/list/';

  // ─── Provider: Dashboard / Jobs ───────────────────────────────────
  static const String proHomepage = '/services/requests/pro/homepage/';
  static const String toggleOnline = '/services/requests/toggle-online/';
  static const String proPrivateRequests = '/services/requests/pro/private/';
  static const String proEmergencyRequests = '/services/requests/pro/emergency/';
  static const String proNewRequests = '/services/requests/pro/requests/';
  static const String proRequests = '/services/requests/pro/requests/';
  static String proRequestRespond(int id) => '/services/requests/$id/respond/';
  static const String proActiveRequests = '/services/requests/pro/active/';
  static String proAdvanceStatus(int id) => '/services/requests/$id/advance-status/';
  static String proLiveLocation(int id) => '/services/requests/$id/live-location/';
  static String proSubmitBill(int id) => '/services/requests/$id/submit-bill/';

  // ─── Provider: Earnings, Reviews ───────────────────────────────────
  static const String proEarnings = '/pro/earnings/';
  static const String reviewsReceived = '/services/reviews/received/';
}