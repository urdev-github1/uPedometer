// lib/controllers/step_counter_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// NEU: Konstante für den SharedPreferences-Schlüssel, um "Magic Strings" zu vermeiden.
const String kInitialStepsKey = 'initialSteps';

/// Verwaltet den Zustand und die Logik des Schrittzählers.
class StepCounterController with ChangeNotifier {
  // Privater Zustand
  int _sessionSteps = 0;
  double _distanceInKm = 0.0;
  String _statusMessage = 'Initialisiere...';
  double _stepLengthInMeters = defaultStepLengthMeters;
  int? _initialSensorSteps;
  int _latestSensorSteps = 0;
  StreamSubscription<StepCount>? _stepCountStreamSubscription;

  // Öffentliche Getter für die UI
  int get sessionSteps => _sessionSteps;
  String get distanceInKm => _distanceInKm.toStringAsFixed(2);
  String get statusMessage => _statusMessage;
  double get stepLengthInCm => _stepLengthInMeters * 100;

  /// Initialisiert den Controller, lädt gespeicherte Werte und startet die Berechtigungsabfrage.
  Future<void> init() async {
    await _loadState();
    await _requestPermissionAndInitStream();
  }

  /// Lädt den gespeicherten Zustand aus SharedPreferences.
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _stepLengthInMeters = prefs.getDouble(stepLengthKey) ?? defaultStepLengthMeters;
    // OPTIMIERT: Verwendung der Konstante anstelle eines "Magic Strings".
    _initialSensorSteps = prefs.getInt(kInitialStepsKey);
    _updateUi();
  }

  /// Frägt die notwendigen Berechtigungen an und startet den Pedometer-Stream.
  Future<void> _requestPermissionAndInitStream() async {
    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus.isGranted) {
      _statusMessage = 'Zähler aktiv';
      _initPedometerStream();
    } else {
      _statusMessage = 'Berechtigung für Aktivitätserkennung verweigert.';
    }
    notifyListeners();
  }

  /// Initialisiert den Stream vom Pedometer-Sensor.
  void _initPedometerStream() {
    _stepCountStreamSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  /// Wird bei jedem neuen Schrittzähler-Event vom Sensor aufgerufen.
  void _onStepCount(StepCount event) async {
    _latestSensorSteps = event.steps;

    // Setze den initialen Wert, falls er noch nicht existiert (erster Start).
    if (_initialSensorSteps == null) {
      _initialSensorSteps = _latestSensorSteps;
      final prefs = await SharedPreferences.getInstance();
      // OPTIMIERT: Verwendung der Konstante.
      await prefs.setInt(kInitialStepsKey, _initialSensorSteps!);
    }

    _updateUi();
  }

  /// Behandelt Fehler vom Sensor-Stream.
  void _onStepCountError(error) {
    // OPTIMIERT: Detailliertere Fehlermeldung für das Debugging und eine klarere Nachricht für den Nutzer.
    debugPrint("Fehler im Pedometer-Stream: $error");
    _statusMessage = 'Sensor nicht verfügbar.';
    _sessionSteps = 0;
    notifyListeners();
  }

  /// Berechnet die aktuellen Werte und benachrichtigt die UI.
  void _updateUi() {
    if (_initialSensorSteps != null) {
      int calculatedSteps = _latestSensorSteps - _initialSensorSteps!;
      // Verhindert negative Schritte, falls der Sensor zurückgesetzt wurde (z.B. Neustart).
      if (calculatedSteps < 0) {
        _initialSensorSteps = _latestSensorSteps;
        calculatedSteps = 0;
      }
      _sessionSteps = calculatedSteps;
      _distanceInKm = (_sessionSteps * _stepLengthInMeters) / 1000;
    }
    notifyListeners();
  }
  
  /// Setzt den Schrittzähler auf 0 zurück.
  Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    _initialSensorSteps = _latestSensorSteps;
    // OPTIMIERT: Verwendung der Konstante.
    await prefs.setInt(kInitialStepsKey, _initialSensorSteps!);
    _statusMessage = 'Zähler zurückgesetzt';
    _updateUi();
  }
  
  /// Aktualisiert die Schrittlänge und speichert sie persistent.
  Future<void> updateStepLength(double newLengthInCm) async {
    _stepLengthInMeters = newLengthInCm / 100.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(stepLengthKey, _stepLengthInMeters);
    _updateUi();
  }

  @override
  void dispose() {
    _stepCountStreamSubscription?.cancel();
    super.dispose();
  }
}