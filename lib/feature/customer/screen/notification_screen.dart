import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NotificationsController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 12.h),
            _buildHeader(),
            SizedBox(height: 20.h),
            Expanded(
              child: Obx(
                    () => c.notifications.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: c.notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: const Color(0xFFEEEEEE),
                    indent: 56.w,
                  ),
                  itemBuilder: (_, index) =>
                      _NotificationTile(notification: c.notifications[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Icon(Icons.chevron_left, size: 28.sp, color: const Color(0xFF212121)),
            ),
          ),
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No notifications yet.',
        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell / alarm icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alarm,
              color: const Color(0xFF1A237E),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      notification.time,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF9E9E9E),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}