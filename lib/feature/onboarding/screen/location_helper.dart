// lib/core/helpers/location_helper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {

  static Future<Position?> getLocation() async {

    // ── 1. Check service enabled ──────────────────────────────────
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Required',
        'Please enable location services and try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return null;
    }

    // ── 2. Check / request permission ────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Location Required',
          'Location permission is required to continue.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied',
        'Please enable location permission in app settings.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      await Geolocator.openAppSettings();
      return null;
    }

    // ── 3. Get current position (30s timeout, retry once) ────────
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        print('📍 [GPS] Attempt $attempt — getting position...');
        final Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
        );
        print('✅ [GPS] Got location: ${pos.latitude}, ${pos.longitude}');
        return pos;
      } catch (e) {
        print('⚠️ [GPS] Attempt $attempt failed: $e');
        if (attempt == 2) {
          Get.snackbar(
            'Location Error',
            'Could not get your location. Please check GPS and try again.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return null;
        }
        // Wait 2 seconds before retry
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return null;
  }
}