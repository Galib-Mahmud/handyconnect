import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Gayathri',
    scaffoldBackgroundColor: const Color.fromRGBO(217, 217, 217, 1),
    primarySwatch: Colors.orange,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromRGBO(217, 217, 217, 1), // ✅ your bg color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.black54),
    ),
  );
}