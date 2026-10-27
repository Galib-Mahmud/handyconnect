import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/address_controller.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AddressController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'saved_addresses'.tr.isNotEmpty ? 'saved_addresses'.tr : 'Saved Addresses',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        if (c.isLoading.value && c.addresses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF8C106)),
          );
        }

        return RefreshIndicator(
          color: const Color(0xFFF8C106),
          onRefresh: c.fetchAddresses,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.addresses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 48.sp, color: const Color(0xFFBDBDBD)),
                        SizedBox(height: 12.h),
                        Text(
                          'No saved addresses yet.',
                          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  )
                else
                  ...c.addresses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final addr = entry.value;
                    return _buildAddressCard(context, c, addr, index + 1);
                  }),

                SizedBox(height: 16.h),

                // Add Address Button
                GestureDetector(
                  onTap: () => _showAddressFormDialog(context, c),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFF8C106), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF8C106).withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_location_alt_outlined, color: const Color(0xFFB45309), size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 60.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAddressCard(
      BuildContext context,
      AddressController c,
      AddressModel addr,
      int number,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8C106).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      addr.title.isNotEmpty ? addr.title : 'Address $number',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  if (addr.isDefault) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAddressFormDialog(context, c, existing: addr),
                    child: Icon(Icons.edit_outlined, size: 18.sp, color: const Color(0xFF757575)),
                  ),
                  SizedBox(width: 14.w),
                  GestureDetector(
                    onTap: () => _confirmDelete(c, addr.id),
                    child: Icon(Icons.delete_outline, size: 18.sp, color: const Color(0xFFE53935)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (addr.building.isNotEmpty) ...[
            Text(
              addr.building,
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF616161)),
            ),
            SizedBox(height: 4.h),
          ],
          Text(
            addr.streetAddress,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF212121)),
          ),
          SizedBox(height: 4.h),
          Text(
            [
              if (addr.city.isNotEmpty) addr.city,
              if (addr.state.isNotEmpty) addr.state,
              if (addr.zipCode.isNotEmpty) addr.zipCode,
              if (addr.country.isNotEmpty) addr.country,
            ].join(', '),
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF757575)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AddressController c, int id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              c.deleteAddress(id);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddressFormDialog(
      BuildContext context,
      AddressController c, {
        AddressModel? existing,
      }) {
    final titleCtrl = TextEditingController(text: existing?.title ?? 'Home');
    final buildingCtrl = TextEditingController(text: existing?.building ?? '');
    final streetCtrl = TextEditingController(text: existing?.streetAddress ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final stateCtrl = TextEditingController(text: existing?.state ?? '');
    final zipCtrl = TextEditingController(text: existing?.zipCode ?? '');
    final countryCtrl = TextEditingController(text: existing?.country ?? 'Germany');

    Get.dialog(
      // Loading cholar shomoy bairer tap-e dialog close hobe na
      barrierDismissible: false,
      PopScope(
        // Loading cholar shomoy back button-o block
        canPop: !c.isSaving.value,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Add Address' : 'Edit Address',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF212121)),
                ),
                const SizedBox(height: 16),
                _buildField(titleCtrl, 'Label / Title (e.g. Home, Office)'),
                const SizedBox(height: 10),
                _buildField(buildingCtrl, 'Building / Apartment'),
                const SizedBox(height: 10),
                _buildField(streetCtrl, 'Street Address *'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildField(cityCtrl, 'City')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(stateCtrl, 'State')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildField(zipCtrl, 'Zip Code')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField(countryCtrl, 'Country')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                            () => OutlinedButton(
                          onPressed: c.isSaving.value ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                            () => ElevatedButton(
                          onPressed: c.isSaving.value
                              ? null
                              : () async {
                            if (streetCtrl.text.trim().isEmpty) {
                              Get.snackbar('Required', 'Street address is required.');
                              return;
                            }
                            bool ok = false;
                            if (existing == null) {
                              ok = await c.addAddress(
                                title: titleCtrl.text,
                                building: buildingCtrl.text,
                                streetAddress: streetCtrl.text,
                                city: cityCtrl.text,
                                state: stateCtrl.text,
                                zipCode: zipCtrl.text,
                                country: countryCtrl.text,
                              );
                            } else {
                              ok = await c.updateAddress(
                                id: existing.id,
                                title: titleCtrl.text,
                                building: buildingCtrl.text,
                                streetAddress: streetCtrl.text,
                                city: cityCtrl.text,
                                state: stateCtrl.text,
                                zipCode: zipCtrl.text,
                                country: countryCtrl.text,
                              );
                            }
                            // API success hole-i dialog close hobe.
                            // Get.back() na, karon controller-er snackbar khola thakle
                            // Get.back() dialog-er bodole snackbar close kore.
                            if (ok) Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8C106),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color(0xFFF8C106).withValues(alpha: 0.6),
                            disabledForegroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: c.isSaving.value
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                              : Text(
                            existing == null ? 'Save' : 'Update',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF8C106)),
        ),
      ),
    );
  }
}