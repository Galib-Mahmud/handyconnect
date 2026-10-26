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
            _buildHeader(c),
            SizedBox(height: 12.h),
            Expanded(
              child: Obx(
                () => c.notifications.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFFF8C106),
                        onRefresh: c.fetchNotifications,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemCount: c.notifications.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: const Color(0xFFEEEEEE),
                            indent: 56.w,
                          ),
                          itemBuilder: (_, index) {
                            final notification = c.notifications[index];
                            return InkWell(
                              onTap: () => c.markAsRead(notification.id),
                              child: _NotificationTile(notification: notification),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationsController c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(Icons.chevron_left, size: 28.sp, color: const Color(0xFF212121)),
              ),
              SizedBox(width: 8.w),
              Text(
                'notifications'.tr.isNotEmpty ? 'notifications'.tr : 'Notifications',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          Obx(() {
            final unread = c.unreadCount;
            if (unread == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: c.markAllAsRead,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8C106).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 48.sp, color: const Color(0xFFBDBDBD)),
          SizedBox(height: 12.h),
          Text(
            'No notifications yet.',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;

    return Container(
      color: isUnread ? const Color(0xFFFFFBEA).withValues(alpha: 0.4) : Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell / alarm icon with unread badge
          Stack(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isUnread ? const Color(0xFFFFF9C4) : const Color(0xFFE8EAF6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: isUnread ? const Color(0xFFF57F17) : const Color(0xFF1A237E),
                  size: 20.sp,
                ),
              ),
              if (isUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
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
                    color: isUnread ? const Color(0xFF424242) : const Color(0xFF9E9E9E),
                    height: 1.4,
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