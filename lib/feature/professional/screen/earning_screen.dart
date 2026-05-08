// lib/features/professional/earnings/views/earnings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:handyConnect/feature/professional/controller/earning_controller.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(EarningsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: SafeArea(
        child: Obx(() => c.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF8C106)))
            : Column(
          children: [
            SizedBox(height: 16.h),
            _buildHeader(),
            SizedBox(height: 16.h),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => c.fetchEarnings(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalEarningsCard(c),
                      SizedBox(height: 14.h),
                      _buildFilterButton(c),
                      SizedBox(height: 14.h),
                      _buildWeekPendingRow(c),
                      SizedBox(height: 20.h),
                      _buildRecentTransactions(c),
                      SizedBox(height: 14.h),
                      _buildBankAccount(),
                      SizedBox(height: 20.h),
                      _buildPayoutHistory(c),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
            _buildWithdrawButton(c),
          ],
        )),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, size: 22.sp, color: const Color(0xFF212121)),
          ),
          SizedBox(width: 14.w),
          Text('Earnings', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(EarningsController c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF8C106), Color(0xFFE6A800)]),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Earnings', style: TextStyle(fontSize: 13.sp, color: Colors.white70)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(c.currency.value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 4.w),
              Text(c.totalEarnings.value, style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 16.sp),
              SizedBox(width: 6.w),
              Text(c.growthPercent.value, style: TextStyle(fontSize: 13.sp, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(EarningsController c) {
    return GestureDetector(
      onTap: () => _showFilterSheet(c),
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(color: const Color(0xFFF8C106), borderRadius: BorderRadius.circular(30.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.selectedFilter.value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(EarningsController c) {
    Get.bottomSheet(Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: c.filters.map((f) => ListTile(
          title: Text(f),
          onTap: () { c.setFilter(f); Get.back(); },
        )).toList(),
      ),
    ));
  }

  Widget _buildWeekPendingRow(EarningsController c) {
    return Row(
      children: [
        Expanded(child: _buildStatBox('This Week', c.thisWeek.value, const Color(0xFF43A047))),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatBox('Pending', c.pending.value, const Color(0xFFF8C106))),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(EarningsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Transactions', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: c.transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = c.transactions[index];
              return ListTile(
                title: Text(t.jobId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                subtitle: Text(t.date, style: TextStyle(fontSize: 12.sp)),
                trailing: Text(t.amount, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccount() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
      child: Row(
        children: [
          Icon(Icons.credit_card, color: Colors.indigo),
          SizedBox(width: 12.w),
          Expanded(child: Text('Bank Hapoalim •••• 4521', style: TextStyle(fontSize: 14.sp))),
          Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory(EarningsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payout History', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: c.payouts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = c.payouts[index];
              return ListTile(
                title: Text(p.amount, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.date),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
                  child: Text(p.status, style: TextStyle(color: Colors.green, fontSize: 11.sp)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawButton(EarningsController c) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: ElevatedButton(
        onPressed: c.requestWithdrawal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8C106),
          minimumSize: Size(double.infinity, 54.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
        child: const Text('Request Withdrawal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}