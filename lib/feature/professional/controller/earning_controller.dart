// lib/features/professional/earnings/controller/earnings_controller.dart

import 'package:get/get.dart';

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';


class TransactionModel {
  final String jobId;
  final String date;
  final String amount;
  final String status;

  TransactionModel({required this.jobId, required this.date, required this.amount, required this.status});
}

class EarningsController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // --- Observables ---
  final RxBool isLoading = false.obs;
  final RxString totalEarnings = "0".obs;
  final RxString thisWeek = "0".obs;
  final RxString pending = "0".obs;
  final RxString currency = "₪".obs;
  final RxString growthPercent = "+12% from last month".obs;

  final RxString selectedFilter = "This Month".obs;
  final List<String> filters = ["This Week", "This Month", "Last 3 Months", "All Time"];

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxList<TransactionModel> payouts = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.get('/pro/earnings/', requiresAuth: true);

      // Map Stats safely
      totalEarnings.value = (response['total_earnings'] ?? 0).toString();
      thisWeek.value = (response['this_week'] ?? 0).toString();
      pending.value = (response['pending'] ?? 0).toString();
      currency.value = response['currency'] ?? "₪";

      // Map Transactions
      if (response['recent_transactions'] != null) {
        final List rawTx = response['recent_transactions'];
        transactions.assignAll(rawTx.map((t) => TransactionModel(
          jobId: t['job_id'] ?? "N/A",
          date: t['date'] ?? "",
          amount: "${currency.value}${t['amount']}",
          status: t['status'] ?? "Completed",
        )).toList());
      }

      // Map Payouts (Using TransactionModel as structure is similar)
      if (response['payout_history'] != null) {
        final List rawPx = response['payout_history'];
        payouts.assignAll(rawPx.map((p) => TransactionModel(
          jobId: p['job_id'] ?? "N/A",
          date: p['date'] ?? "",
          amount: "${currency.value}${p['amount']}",
          status: p['status'] ?? "Completed",
        )).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch earnings");
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    fetchEarnings();
  }

  void requestWithdrawal() {
    if (double.parse(totalEarnings.value) > 0) {
      Get.snackbar("Success", "Withdrawal request sent!");
    } else {
      Get.snackbar("Notice", "No earnings to withdraw");
    }
  }
}