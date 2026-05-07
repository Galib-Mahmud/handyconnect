
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewModel {
  final String initials;
  final Color color;
  final String name;
  final int stars;
  final String comment;

  const ReviewModel({
    required this.initials,
    required this.color,
    required this.name,
    required this.stars,
    required this.comment,
  });
}

class ProfessionalProfileController extends GetxController {
  final selectedTab = 0.obs; // 0 = Government ID, 1 = Certificates

  final name = 'Michael Ben'.obs;
  final email = 'michealben@gmail.com'.obs;
  final radiusKm = '10km'.obs;
  final totalJobs = 342.obs;
  final rating = 4.2.obs;

  final reviews = <ReviewModel>[
    const ReviewModel(
      initials: 'DC',
      color: Color(0xFF00ACC1),
      name: 'David Cohen',
      stars: 4,
      comment: 'Excellent work, very professional!',
    ),
    const ReviewModel(
      initials: 'SL',
      color: Color(0xFFE53935),
      name: 'Sarah Levi',
      stars: 4,
      comment: 'Fixed the issue quickly. Highly recommend!',
    ),
  ].obs;

  void selectTab(int index) => selectedTab.value = index;
}