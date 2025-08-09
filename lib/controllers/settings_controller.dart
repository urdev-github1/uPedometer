// lib/controllers/settings_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Schlüssel für SharedPreferences
const String kTrackingIntervalKey = 'settings_trackingInterval';
const String kAccuracyBufferKey = 'settings_accuracyBuffer';
const String kTimeFilterEnabledKey = 'settings_timeFilterEnabled';
const String kTimeFilterValueKey = 'settings_timeFilterValue';

class SettingsController with ChangeNotifier {
  // Private Variablen mit Standardwerten
  int _trackingInterval = 7;     // Standard: 7 Sekunden
  double _accuracyBuffer = 2.0;   // Standard: 2.0 Meter
  bool _isTimeFilterEnabled = false; // Standard: Aus
  int _timeFilterValue = 5;       // Standard: 5 Sekunden

  // Öffentliche Getter, damit der Rest der App die Werte lesen kann
  int get trackingInterval => _trackingInterval;
  double get accuracyBuffer => _accuracyBuffer;
  bool get isTimeFilterEnabled => _isTimeFilterEnabled;
  int get timeFilterValue => _timeFilterValue;

  SettingsController() {
    loadSettings(); // Einstellungen beim Start laden
  }

  /// Lädt alle Einstellungen aus SharedPreferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _trackingInterval = prefs.getInt(kTrackingIntervalKey) ?? 7;
    _accuracyBuffer = prefs.getDouble(kAccuracyBufferKey) ?? 2.0;
    _isTimeFilterEnabled = prefs.getBool(kTimeFilterEnabledKey) ?? false;
    _timeFilterValue = prefs.getInt(kTimeFilterValueKey) ?? 5;
    notifyListeners(); // UI benachrichtigen, dass die Werte geladen sind
  }

  // --- Methoden zum Aktualisieren der einzelnen Werte ---

  Future<void> updateTrackingInterval(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    _trackingInterval = newValue;
    await prefs.setInt(kTrackingIntervalKey, newValue);
    notifyListeners();
  }

  Future<void> updateAccuracyBuffer(double newValue) async {
    final prefs = await SharedPreferences.getInstance();
    _accuracyBuffer = newValue;
    await prefs.setDouble(kAccuracyBufferKey, newValue);
    notifyListeners();
  }

  Future<void> updateTimeFilterEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    _isTimeFilterEnabled = isEnabled;
    await prefs.setBool(kTimeFilterEnabledKey, isEnabled);
    notifyListeners();
  }
    
  Future<void> updateTimeFilterValue(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    _timeFilterValue = newValue;
    await prefs.setInt(kTimeFilterValueKey, newValue);
    notifyListeners();
  }
}