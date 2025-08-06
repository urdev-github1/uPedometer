import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controllers/location_tracker_controller.dart';

// =======================================================================
// HAUPT-WIDGET: MapScreen (StatefulWidget)
// =======================================================================
class MapScreen extends StatefulWidget {
  final PageController pageController;

  const MapScreen({
    super.key,
    required this.pageController,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  bool _isMapReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.contains(ConnectivityResult.mobile) ||
                          results.contains(ConnectivityResult.wifi) ||
                          results.contains(ConnectivityResult.ethernet);
    if (mounted && _hasInternet != hasConnection) {
      setState(() => _hasInternet = hasConnection);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live-Karte'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.gps_fixed),
            tooltip: 'Zum Haupt-Tracker',
            onPressed: () => widget.pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
      // HINWEIS: Der Body wird jetzt basierend auf dem Internetstatus und dem Tracking-Status aufgebaut.
      // Die Logik ist viel klarer strukturiert.
      body: _buildBody(),
    );
  }

  /// Baut den Body des Scaffolds basierend auf dem aktuellen Zustand.
  Widget _buildBody() {
    if (!_hasInternet) {
      return const _NoInternetWarning();
    }

    return Consumer<LocationTrackerController>(
      builder: (context, controller, child) {
        final bool isTrackingActive = controller.isTracking && controller.currentPosition != null;
        final bool hasRouteData = controller.route.isNotEmpty || controller.currentPosition != null;

        if (!hasRouteData) {
          // Zeigt einen Hilfetext, wenn weder eine Route noch eine Position vorhanden ist.
          return _HelpText(
            message: controller.isTracking ? 'GPS-Signal wird gesucht...' : null,
          );
        }

        // Wenn Daten vorhanden sind, zeige die Karte.
        return _MapView(
          mapController: _mapController,
          route: controller.route,
          currentPosition: controller.currentPosition,
          isMapReady: _isMapReady,
          onMapReady: () {
            if (mounted) setState(() => _isMapReady = true);
          },
          isTracking: isTrackingActive,
        );
      },
    );
  }
}


// =======================================================================
// NEU: Dediziertes Widget für die Kartenansicht
// =======================================================================
class _MapView extends StatelessWidget {
  final MapController mapController;
  final List<LatLng> route;
  final dynamic currentPosition; // Position-Objekt aus geolocator
  final bool isMapReady;
  final VoidCallback onMapReady;
  final bool isTracking;

  const _MapView({
    required this.mapController,
    required this.route,
    this.currentPosition,
    required this.isMapReady,
    required this.onMapReady,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    // Zentriert die Karte automatisch, wenn das Tracking aktiv ist.
    if (isTracking && isMapReady && currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          mapController.camera.zoom,
        );
      });
    }

    // Bestimmt den initialen Mittelpunkt der Karte.
    LatLng initialCenter;
    if (currentPosition != null) {
      initialCenter = LatLng(currentPosition.latitude, currentPosition.longitude);
    } else {
      initialCenter = route.last;
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 17.0, // Der Zoom-Level wurde hier belassen
        onMapReady: onMapReady,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        if (route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: route, strokeWidth: 4.0, color: Colors.blue),
            ],
          ),
        if (currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(currentPosition.latitude, currentPosition.longitude),
                child: _LocationMarker(heading: currentPosition.heading),
              ),
            ],
          ),
      ],
    );
  }
}


// =======================================================================
// NEU: Kleinere, private Helper-Widgets
// =======================================================================

/// Zeigt den Marker für die aktuelle Position an.
class _LocationMarker extends StatelessWidget {
  final double heading;
  const _LocationMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading * math.pi / 180),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.navigation, color: Colors.white, size: 38.0),
          Icon(Icons.navigation, color: Colors.blue.shade700, size: 28.0),
        ],
      ),
    );
  }
}

/// Zeigt eine Warnung bei fehlender Internetverbindung.
class _NoInternetWarning extends StatelessWidget {
  const _NoInternetWarning();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30.0),
        child: Text(
          'Keine Internetverbindung. Die Karte kann nicht geladen werden.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Zeigt einen allgemeinen Hilfetext an.
class _HelpText extends StatelessWidget {
  final String? message;
  const _HelpText({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Text(
          message ?? 'Starte das GPS-Tracking auf dem Haupt-Screen, um hier die Live-Route zu sehen.',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}