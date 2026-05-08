// lib/features/professional/chat/view/professional_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../route/route_name.dart';
import '../controller/chat_controller.dart';


class ProfessionalChatScreen extends StatelessWidget {
  const ProfessionalChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is registered by the caller via Get.put() before navigating
    final c = Get.find<ProfessionalChatController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(c: c),
            Expanded(child: _MessageList(c: c)),
            _BottomSection(c: c),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back,
                color: const Color(0xFF212121), size: 24.sp),
          ),
          SizedBox(width: 10.w),

          // Avatar
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: c.clientPhoto.isNotEmpty
                ? NetworkImage(c.clientPhoto)
                : const AssetImage('assets/images/profile/profile.png')
            as ImageProvider,
          ),
          SizedBox(width: 10.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.clientName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.jobLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFF8C106),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Live / Reconnecting dot
                    Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.isConnected.value
                                ? const Color(0xFF4CAF50)
                                : Colors.orange,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          c.isConnected.value
                              ? 'Live'
                              : 'Reconnecting…',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: c.isConnected.value
                                ? const Color(0xFF4CAF50)
                                : Colors.orange,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message List
// ─────────────────────────────────────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  const _MessageList({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value && c.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF8C106)),
        );
      }

      if (c.messages.isEmpty) {
        return Center(
          child: Text(
            'No messages yet.\nSay hello! 👋',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.sp, color: const Color(0xFFBDBDBD)),
          ),
        );
      }

      return ListView.builder(
        controller: c.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: c.messages.length + 1, // +1 for date header
        itemBuilder: (context, index) {
          if (index == 0) return const _DateSeparator(label: 'Today');
          return _MessageBubble(message: c.messages[index - 1]);
        },
      );
    });
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFFBDBDBD),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isSentByMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment:
        mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
            mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: 280.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color:
                mine ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft    : Radius.circular(18.r),
                  topRight   : Radius.circular(18.r),
                  bottomLeft : mine
                      ? Radius.circular(18.r)
                      : Radius.circular(4.r),
                  bottomRight: mine
                      ? Radius.circular(4.r)
                      : Radius.circular(18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: mine
                      ? Colors.white
                      : const Color(0xFF212121),
                  height: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              message.status != null
                  ? '${message.time}  •  ${message.status}'
                  : message.time,
              style: TextStyle(
                  fontSize: 11.sp, color: const Color(0xFFBDBDBD)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Section
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          _InputRow(c: c),
          SizedBox(height: 12.h),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          SizedBox(height: 12.h),
          const _BudgetCard(),
          SizedBox(height: 12.h),
          const _ConfirmButton(),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Make sure price & timing are confirmed before proceeding.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Row
// ─────────────────────────────────────────────────────────────────────────────
class _InputRow extends StatelessWidget {
  const _InputRow({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        constraints: BoxConstraints(minHeight: 48.h),
        padding:
        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(24.r),
          border:
          Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined,
                color: const Color(0xFFBDBDBD), size: 22.sp),
            SizedBox(width: 10.w),

            // Text field
            Expanded(
              child: TextField(
                controller: c.textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => c.sendMessage(),
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF212121),
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFFBDBDBD),
                    height: 1.4,
                  ),
                  border        : InputBorder.none,
                  enabledBorder : InputBorder.none,
                  focusedBorder : InputBorder.none,
                  isDense       : true,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Send button
            GestureDetector(
              onTap: c.sendMessage,
              child: Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: c.isConnected.value
                    ? Icon(
                  Icons.send_rounded,
                  key: const ValueKey('send'),
                  color: const Color(0xFF2196F3),
                  size: 22.sp,
                )
                    : Icon(
                  Icons.send_rounded,
                  key: const ValueKey('send_offline'),
                  color: const Color(0xFFBDBDBD),
                  size: 22.sp,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget Card
// ─────────────────────────────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFF8C106), width: 2),
              ),
              child: Center(
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8C106),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget discussed',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    "Let's confirm the location & timing.",
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF757575)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm & Schedule Button
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () => Get.toNamed(RouteName.location),
        child: Container(
          height: 52.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF8C106),
            borderRadius: BorderRadius.circular(26.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Confirm & Schedule',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}