import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controller/chat_controller.dart';

class ProfessionalChatScreen extends StatelessWidget {
  final ProfessionalChatController controller;

  const ProfessionalChatScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.put(controller);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(c),        // ✅ passes c explicitly
      body: Column(
        children: [
          Expanded(child: _MessageList(c: c)),
          _BottomInputSection(c: c),
        ],
      ),
    );
  }

  // ✅ c passed as parameter — no longer relies on Get.arguments
  PreferredSizeWidget _buildAppBar(ProfessionalChatController c) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: c.clientPhoto.isNotEmpty
                ? NetworkImage(c.clientPhoto)
                : null,
            child: c.clientPhoto.isEmpty
                ? Icon(Icons.person, size: 20.sp, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.clientName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                c.jobLabel,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFFFB300),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        controller: c.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        itemCount: c.messages.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Text("Today", style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
              ),
            );
          }
          final msg = c.messages[index - 1];
          return _ChatBubble(message: msg);
        },
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final dynamic message; // Replace with ChatMessage model

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isSentByMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFFB300) : Colors.white,
              border: isMe ? null : Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
                bottomRight: Radius.circular(isMe ? 4.r : 20.r),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "${message.time}${isMe ? '  •  ${message.status}' : ''}",
            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BottomInputSection extends StatelessWidget {
  const _BottomInputSection({required this.c});
  final ProfessionalChatController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image_outlined, color: Colors.grey, size: 24.sp),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: c.textController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor: const Color(0xFFE8EAF6),
              radius: 18.r,
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: Colors.grey, size: 18.sp),
                onPressed: c.sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}