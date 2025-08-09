// lib/controllers/location_tracker_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

// =============================================================== //
// --- NEUER IMPORT, UM AUF DEN SETTINGS CONTROLLER ZUGREIFEN ZU KÖNNEN --- //
// =============================================================== //
import 'settings_controller.dart'; 

// =============================================================== //
// --- IMPORTS FÜR DIE PRÜFUNG DER ANDROID-VERSION ---             //
// =============================================================== //
import 'dart:io'; // Erforderlich für die Prüfung der Plattform (Android/iOS).
import 'package:device_info_plus/device_info_plus.dart'; // Für die Abfrage der SDK-Version.

// Schlüssel für die persistenten Daten in SharedPreferences.
const String kTotalDistanceKey = 'total_distance';
const String kIsTrackingKey = 'is_tracking_active';
const String kStartTimeKey = 'start_time';
const String kStopTimeKey = 'stop_time';
const String kAddressKey = 'address';
const String kRoutePointsKey = 'route_points'; // Für die Routenpunkte

// Ein Enum, um das Ergebnis des Startversuchs klar zu signalisieren.
enum TrackingStartResult {
  success,
  locationDenied,
  notificationDenied,
}

/// Verwaltet die Logik für das GPS-Tracking und speichert den Zustand persistent.
class LocationTrackerController with ChangeNotifier {
  double _totalDistance = 0.0;
  bool _isTracking = false;
  String _statusMessage = 'Lade Zustand...';
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;

  // Zeitstempel für den zuletzt gespeicherten Punkt (für den Zeitfilter)
  DateTime? _lastPointTime;

  final List<LatLng> _routePoints = [];

  String? _address;
  bool _isFetchingAddress = false;

  // =============================================================== //
  // --- NEU: Eine Referenz auf den SettingsController ---           //
  // =============================================================== //
  SettingsController? _settingsController;

  // Getter für die UI
  Position? get currentPosition => _lastPosition;
  List<LatLng> get route => _routePoints;
  double get totalDistanceInKm => _totalDistance / 1000;
  bool get isTracking => _isTracking;
  String get statusMessage => _statusMessage;
  String? get address => _address;
  bool get isFetchingAddress => _isFetchingAddress;

  DateTime? _startTime;
  DateTime? _stopTime;

  DateTime? get startTime => _startTime;
  DateTime? get stopTime => _stopTime;

  /// Gibt die formatierte Dauer des Trackings zurück.
  String get trackingDurationFormatted {
    if (_startTime == null) return '00:00';
    final endTime = _stopTime ?? DateTime.now();
    final duration = endTime.difference(_startTime!);
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Initialisiert den Controller und lädt den gespeicherten Zustand.
  Future<void> init() async {
    await _loadState();
    if (_isTracking) {
      _isTracking = false; // Tracking-Zustand zurücksetzen
      _statusMessage = 'Tracking wurde unterbrochen. Bitte neu starten.';
      await _saveState();
      notifyListeners();
    }
  }

  /// Lädt den Zustand aus SharedPreferences.
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _totalDistance = prefs.getDouble(kTotalDistanceKey) ?? 0.0;
    _isTracking = prefs.getBool(kIsTrackingKey) ?? false;

    final startTimeMillis = prefs.getInt(kStartTimeKey);
    _startTime = startTimeMillis != null ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis) : null;

    final stopTimeMillis = prefs.getInt(kStopTimeKey);
    _stopTime = stopTimeMillis != null ? DateTime.fromMillisecondsSinceEpoch(stopTimeMillis) : null;

    _address = prefs.getString(kAddressKey);

    final String? savedRoute = prefs.getString(kRoutePointsKey);
    if (savedRoute != null) {
      final List<dynamic> decodedList = json.decode(savedRoute);
      _routePoints.clear();
      _routePoints.addAll(decodedList.map<LatLng>((item) => LatLng(item['lat'], item['lng'])));
    }
    
    if (_isTracking) {
      _statusMessage = 'Tracking wird fortgesetzt...';
    } else if (_totalDistance > 0) {
      _statusMessage = 'Tracking gestoppt. Distanz: ${totalDistanceInKm.toStringAsFixed(2)} km';
    } else {
      _statusMessage = 'Drücke Start, um das Tracking zu beginnen.';
    }
    notifyListeners();
  }

  /// Speichert den aktuellen Zustand in SharedPreferences.
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kTotalDistanceKey, _totalDistance);
    await prefs.setBool(kIsTrackingKey, _isTracking);

    if (_startTime != null) {
      await prefs.setInt(kStartTimeKey, _startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(kStartTimeKey);
    }
    if (_stopTime != null) {
      await prefs.setInt(kStopTimeKey, _stopTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(kStopTimeKey);
    }
    if (_address != null) {
      await prefs.setString(kAddressKey, _address!);
    } else {
      await prefs.remove(kAddressKey);
    }

    if (_routePoints.isNotEmpty) {
      final List<Map<String, double>> routePointsAsMap =
          _routePoints.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList();
      await prefs.setString(kRoutePointsKey, json.encode(routePointsAsMap));
    } else {
      await prefs.remove(kRoutePointsKey);
    }
  }

  // =============================================================== //
  // --- ANPASSUNG: startTracking akzeptiert nun den Controller ---   //
  // =============================================================== //
  /// Startet den Tracking-Vorgang und verwendet die Einstellungen dynamisch.
  Future<TrackingStartResult> startTracking({
    required SettingsController settingsController,
  }) async {
    // Speichere eine Referenz auf den Controller, um live auf Einstellungen zugreifen zu können.
    _settingsController = settingsController;

    // Schritt 1: Standortberechtigung prüfen.
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      _isTracking = false;
      _statusMessage = 'Standortberechtigung verweigert.';
      await _saveState();
      notifyListeners();
      return TrackingStartResult.locationDenied;
    }

    // Schritt 2: Benachrichtigungsberechtigung prüfen (nur für Android SDK 33+).
    bool notificationsGranted = true;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          notificationsGranted = false;
        }
      }
    }

    if (!notificationsGranted) {
      _isTracking = false;
      _statusMessage = 'Für das Tracking müssen Benachrichtigungen erlaubt sein.';
      await _saveState();
      notifyListeners();
      return TrackingStartResult.notificationDenied;
    }

    // Schritt 3: Tracking-Prozess starten.
    if (_isTracking && _positionStreamSubscription != null) return TrackingStartResult.success;

    if (!_isTracking) {
      _startTime = DateTime.now();
      _stopTime = null;
      _routePoints.clear();
    }

    _isTracking = true;
    _statusMessage = 'Tracking aktiv...';
    _lastPosition = null;
    _lastPointTime = null;

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      // Das Abfrageintervall wird hier einmalig aus den aktuellen Einstellungen gelesen.
      intervalDuration: Duration(seconds: _settingsController!.trackingInterval),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Tracking aktiv",
        notificationText: "Deine Route wird aufgezeichnet.",
        enableWakeLock: true,
        notificationIcon: AndroidResource(name: 'notification_icon'),
      ),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        // ======================================================================= //
        // --- ANPASSUNG: Dynamische Filterlogik mit Live-Einstellungen ---        //
        // ======================================================================= //
        final DateTime now = DateTime.now();

        // Sicherheitsabfrage, falls der Controller nicht verfügbar ist.
        if (_settingsController == null) return;

        // Wenn es der allererste Punkt ist, speichere ihn direkt.
        if (_lastPosition == null) {
          _lastPosition = position;
          _lastPointTime = now;
          _routePoints.add(LatLng(position.latitude, position.longitude));
          _saveState();
          notifyListeners();
          return; // Verarbeitung für diesen Punkt hier beenden.
        }
        
        // Bedingung 1: Distanzfilter (liest den Wert live aus dem Controller)
        final double minDistanceThreshold = position.accuracy + _settingsController!.accuracyBuffer;
        final double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Wenn die Distanz nicht ausreicht, wird der Punkt ignoriert.
        if (distance < minDistanceThreshold) {
          return;
        }

        // Bedingung 2: Zeitfilter (liest die Werte live aus dem Controller)
        if (_settingsController!.isTimeFilterEnabled) {
          final int secondsSinceLastPoint = now.difference(_lastPointTime!).inSeconds;
          // Wenn die Mindestzeit noch nicht vergangen ist, wird der Punkt ignoriert.
          if (secondsSinceLastPoint < _settingsController!.timeFilterValue) {
            return;
          }
        }

        // Wenn alle Bedingungen erfüllt sind, wird der Punkt verarbeitet.
        _totalDistance += distance;
        _lastPosition = position;
        _lastPointTime = now; // Zeitstempel aktualisieren
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _saveState();
        notifyListeners();
        // =============================================================== //
        // --- ANPASSUNG ENDE ---                                          //
        // =============================================================== //
      },
      onError: (error) {
        _statusMessage = 'Fehler beim GPS-Empfang.';
        notifyListeners();
      },
    );

    await _saveState();
    notifyListeners();
    return TrackingStartResult.success;
  }

  /// Stoppt den Tracking-Vorgang.
  void stopTracking() {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _stopTime = DateTime.now();
    // =============================================================== //
    // --- NEU: Referenz auf den SettingsController entfernen ---      //
    // =============================================================== //
    _settingsController = null;
    _statusMessage = 'Tracking gestoppt. Distanz: ${totalDistanceInKm.toStringAsFixed(2)} km';
    _saveState();
    notifyListeners();
  }
  
  String _formatPlacemark(Placemark placemark) {
    String street = placemark.street ?? '';
    String cityLine = '${placemark.postalCode ?? ''} ${placemark.locality ?? ''}'.trim();

    if (street.isEmpty) return cityLine;
    if (cityLine.isEmpty) return street;
    
    return '$street\n$cityLine';
  }

  Future<void> fetchAddress() async {
    if (_isFetchingAddress) return;
    _isFetchingAddress = true;
    notifyListeners();

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        _address = _formatPlacemark(placemarks.first);
      } else {
        _address = 'Adresse nicht gefunden';
      }
    } catch (e) {
      _address = 'Fehler bei Adressabruf';
    }

    _isFetchingAddress = false;
    await _saveState();
    notifyListeners();
  }

  void resetTracking() {
    if (_isTracking) {
      stopTracking();
    }

    _totalDistance = 0.0;
    _startTime = null;
    _stopTime = null;
    _address = null;
    _routePoints.clear();
    _lastPosition = null;
    _lastPointTime = null;
    _statusMessage = 'Drücke Start, um das Tracking zu beginnen.';
    // =============================================================== //
    // --- NEU: Referenz auch hier sicherheitshalber entfernen ---     //
    // =============================================================== //
    _settingsController = null;

    _saveState();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}