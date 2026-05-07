import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address 1 Header
              Text(
                'Address 1',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),

              SizedBox(height: 16.h),

              // Home Label Input
              _buildInputField(
                hintText: 'Home',
              ),

              SizedBox(height: 12.h),

              // Building/Apartment
              _buildInputField(
                hintText: 'Buzz apartment 48',
              ),

              SizedBox(height: 12.h),

              // Street Address
              _buildInputField(
                hintText: '123 Main St, Apt 48',
              ),

              SizedBox(height: 12.h),

              // City and State Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      hintText: 'New York',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildInputField(
                      hintText: 'California',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Zip Code and Country Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      hintText: '10001',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildInputField(
                      hintText: 'United States',
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Add Address Button
              GestureDetector(
                onTap: () {
                  // Handle add address
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add Address',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.add,
                        color: const Color(0xFF212121),
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String hintText}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Text(
        hintText,
        style: TextStyle(
          fontSize: 14.sp,
          color: const Color(0xFF757575),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}