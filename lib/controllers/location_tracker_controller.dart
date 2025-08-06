// lib/controllers/location_tracker_controller.dart

import 'dart:async';
import 'dart:convert'; // HINZUGEFÜGT: Für die JSON-Konvertierung
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

// Schlüssel für die persistenten Daten in SharedPreferences.
const String kTotalDistanceKey = 'total_distance';
const String kIsTrackingKey = 'is_tracking_active';
const String kStartTimeKey = 'start_time';
const String kStopTimeKey = 'stop_time';
const String kAddressKey = 'address';
const String kRoutePointsKey = 'route_points'; // HINZUGEFÜGT: Für die Routenpunkte

/// Verwaltet die Logik für das GPS-Tracking und speichert den Zustand persistent.
class LocationTrackerController with ChangeNotifier {
  double _totalDistance = 0.0;
  bool _isTracking = false;
  String _statusMessage = 'Lade Zustand...';
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;

  // --- TEMPORÄR ZUM TESTEN ---
  int _trackingInterval = 3; // Standardwert, z.B. 3 Sekunden
  int get trackingInterval => _trackingInterval;
  // --- ENDE TEMPORÄR ---

  final List<LatLng> _routePoints = [];

  String? _address;
  bool _isFetchingAddress = false;

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
      // Wenn das Tracking beim letzten Mal aktiv war, starte es erneut.
      await startTracking();
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

    // --- ROUTENPUNKTE LADEN ---
    final String? savedRoute = prefs.getString(kRoutePointsKey);
    if (savedRoute != null) {
      final List<dynamic> decodedList = json.decode(savedRoute);
      _routePoints.clear();
      _routePoints.addAll(decodedList.map<LatLng>((item) => LatLng(item['lat'], item['lng'])));
    }
    // --- ENDE ---

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

    // --- ROUTENPUNKTE SPEICHERN ---
    if (_routePoints.isNotEmpty) {
      final List<Map<String, double>> routePointsAsMap = _routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();
      await prefs.setString(kRoutePointsKey, json.encode(routePointsAsMap));
    } else {
      await prefs.remove(kRoutePointsKey);
    }
    // --- ENDE ---
  }

  // --- TEMPORÄR ZUM TESTEN ---
  /// Aktualisiert das Tracking-Intervall und startet das Tracking neu, wenn es aktiv ist.
  void updateTrackingInterval(int newInterval) {
    if (_trackingInterval == newInterval) return;

    _trackingInterval = newInterval;
    notifyListeners(); // UI sofort aktualisieren (Slider-Anzeige)

    // Wenn das Tracking bereits läuft, stoppen und mit dem neuen Intervall neu starten.
    if (_isTracking) {
      stopTracking();
      startTracking();
    }
  }
  // --- ENDE TEMPORÄR ---

  /// Startet den Tracking-Vorgang.
  Future<void> startTracking() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      if (_isTracking && _positionStreamSubscription != null) return;

      if (!_isTracking) {
        _startTime = DateTime.now();
        _stopTime = null;
        _routePoints.clear(); // Nur beim expliziten Start die Route zurücksetzen
      }

      _isTracking = true;
      _statusMessage = 'Tracking aktiv...';
      _lastPosition = null;

      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        // ÄNDERUNG: Verwende die neue Variable statt des festen Werts
        intervalDuration: Duration(seconds: _trackingInterval), 
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Tracking aktiv",
          notificationText: "Ihre Route wird aufgezeichnet.",
          enableWakeLock: true,
        ),
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          if (_lastPosition != null) {
            double distance = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            _totalDistance += distance;
          }
          _lastPosition = position;
          _routePoints.add(LatLng(position.latitude, position.longitude));
          _saveState(); // Zustand speichern inkl. der neuen Route
          notifyListeners();
        },
        onError: (error) {
          _statusMessage = 'Fehler beim GPS-Empfang.';
          notifyListeners();
        },
      );

      await _saveState();
      notifyListeners();
    } else {
      _isTracking = false;
      _statusMessage = 'Standortberechtigung verweigert.';
      await _saveState();
      notifyListeners();
    }
  }

  /// Stoppt den Tracking-Vorgang.
  void stopTracking() {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _stopTime = DateTime.now();
    _statusMessage = 'Tracking gestoppt. Distanz: ${totalDistanceInKm.toStringAsFixed(2)} km';
    _saveState();
    notifyListeners();
  }

  // =============================================================== //
  // --- ANPASSUNG START: Zweizeilige Adressformatierung ---         //
  // =============================================================== //
  /// Formatiert ein Placemark-Objekt in einen zweizeiligen, lesbaren String.
  String _formatPlacemark(Placemark placemark) {
    // Straße und Hausnummer extrahieren
    String street = placemark.street ?? '';
    
    // Postleitzahl und Ort zu einer Zeile zusammenfügen.
    // .trim() entfernt führende/nachgestellte Leerzeichen, falls einer der Werte fehlt.
    String cityLine = '${placemark.postalCode ?? ''} ${placemark.locality ?? ''}'.trim();

    // Wenn die Straße leer ist, nur die Stadt-Zeile zurückgeben.
    if (street.isEmpty) {
      return cityLine;
    }
    
    // Wenn die Stadt-Zeile leer ist, nur die Straße zurückgeben.
    if (cityLine.isEmpty) {
      return street;
    }

    // Beide Teile mit einem Zeilenumbruch (\n) kombinieren.
    return '$street\n$cityLine';
  }
  // =============================================================== //
  // --- ANPASSUNG ENDE ---                                          //
  // =============================================================== //


  /// Ruft die aktuelle Position ab und ermittelt die zugehörige Adresse.
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

  /// Setzt alle Tracking-Daten zurück.
  void resetTracking() {
    if (_isTracking) {
      // Stoppt das Tracking, wenn es aktiv ist, aber löscht die Daten noch nicht
      stopTracking();
    }

    _totalDistance = 0.0;
    _startTime = null;
    _stopTime = null;
    _address = null;
    _routePoints.clear(); // Leert die Routenpunkte im Arbeitsspeicher
    _statusMessage = 'Drücke Start, um das Tracking zu beginnen.';

    _saveState(); // Speichert den leeren Zustand (inkl. leerer Route)
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}