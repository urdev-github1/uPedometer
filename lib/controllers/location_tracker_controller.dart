// lib/controllers/location_tracker_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'settings_controller.dart'; 
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

// Schlüssel für die persistenten Daten in SharedPreferences.
const String kTotalDistanceKey = 'total_distance';
const String kIsTrackingKey = 'is_tracking_active';
const String kStartTimeKey = 'start_time';
const String kStopTimeKey = 'stop_time';
const String kAddressKey = 'address';
const String kRoutePointsKey = 'route_points';

enum TrackingStartResult {
  success,
  locationDenied,
  notificationDenied,
}

class LocationTrackerController with ChangeNotifier {
  double _totalDistance = 0.0;
  bool _isTracking = false;
  String _statusMessage = 'Lade Zustand...';
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  DateTime? _lastPointTime;
  final List<LatLng> _routePoints = [];
  String? _address;
  bool _isFetchingAddress = false;
  SettingsController? _settingsController;

  // Getter
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

  String get trackingDurationFormatted {
    if (_startTime == null) return '00:00';
    final endTime = _stopTime ?? DateTime.now();
    final duration = endTime.difference(_startTime!);
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  // =============================================================== //
  // --- KORRIGIERTE init() METHODE ---                              //
  // =============================================================== //
  /// Initialisiert den Controller und lädt den gespeicherten Zustand.
  Future<void> init() async {
    await _loadState();
    // Der problematische Code-Block, der das Tracking beendet hat, wurde entfernt.
    // Wenn die App neu gestartet wird, wird der Tracking-Status jetzt korrekt
    // aus SharedPreferences geladen und beibehalten, sodass der Vordergrund-Dienst
    // nahtlos weitermacht und die UI den korrekten Zustand anzeigt.
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

  /// Startet den Tracking-Vorgang und verwendet die Einstellungen dynamisch.
  Future<TrackingStartResult> startTracking({
    required SettingsController settingsController,
  }) async {
    _settingsController = settingsController;

    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      _isTracking = false;
      _statusMessage = 'Standortberechtigung verweigert.';
      await _saveState();
      notifyListeners();
      return TrackingStartResult.locationDenied;
    }

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
        final DateTime now = DateTime.now();
        if (_settingsController == null) return;

        if (_lastPosition == null) {
          _lastPosition = position;
          _lastPointTime = now;
          _routePoints.add(LatLng(position.latitude, position.longitude));
          _saveState();
          notifyListeners();
          return;
        }
        
        final double minDistanceThreshold = position.accuracy + _settingsController!.accuracyBuffer;
        final double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < minDistanceThreshold) {
          return;
        }

        if (_settingsController!.isTimeFilterEnabled) {
          final int secondsSinceLastPoint = now.difference(_lastPointTime!).inSeconds;
          if (secondsSinceLastPoint < _settingsController!.timeFilterValue) {
            return;
          }
        }

        _totalDistance += distance;
        _lastPosition = position;
        _lastPointTime = now;
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _saveState();
        notifyListeners();
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