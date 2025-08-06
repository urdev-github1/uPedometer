// lib/notifiers/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Schlüssel zum Speichern der Theme-Einstellung
const String themeModeKey = 'themeMode';

// Diese Klasse verwaltet den Theme-Status der App.
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Standardmäßig ist das dunkle Theme aktiv.

  ThemeMode get themeMode => _themeMode;

  // Konstruktor, der sofort die gespeicherte Einstellung lädt.
  ThemeNotifier() {
    _loadThemeFromPrefs();
  }

  // Schaltet zwischen hellem und dunklem Theme um.
  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveThemeToPrefs();
    notifyListeners(); // Benachrichtigt alle Widgets, die zuhören.
  }

  // Lädt die Theme-Einstellung aus SharedPreferences.
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(themeModeKey) ?? true; // Standard: dark
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Speichert die aktuelle Theme-Einstellung.
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeModeKey, _themeMode == ThemeMode.dark);
  }
}