// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

// Das dunkle Theme für die App.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF0A0E21),
  scaffoldBackgroundColor: const Color(0xFF0A0E21),
  cardColor: const Color(0xFF1D1E33), // Farbe für Karten wie InfoCard
  hintColor: Colors.tealAccent, // Akzentfarbe
  // KORREKT: Verwenden Sie DialogThemeData für die dialogTheme-Eigenschaft.
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1D1E33),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0E21),
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.tealAccent,
      foregroundColor: Colors.black,
    ),
  ),
);

// Das helle Theme für die App.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.teal,
  scaffoldBackgroundColor: const Color(0xFFF0F0F0), // Ein leicht grauer Hintergrund
  cardColor: Colors.white, // Karten sind weiß
  hintColor: Colors.deepPurpleAccent, // Eine andere Akzentfarbe für den Kontrast
  // KORREKT: Verwenden Sie DialogThemeData für die dialogTheme-Eigenschaft.
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black54),
    titleLarge: TextStyle(color: Colors.black),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white, // Text und Icons in der AppBar
    elevation: 2,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
    ),
  ),
);