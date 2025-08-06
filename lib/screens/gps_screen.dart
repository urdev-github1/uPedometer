// lib/screens/gps_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/location_tracker_controller.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Zustand des Screens beim Wischen beibehalten

  @override
  Widget build(BuildContext context) {
    super.build(context); // Notwendig für den Mixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS-Status'),
        centerTitle: true,
        // Verhindert, dass der Zurück-Button angezeigt wird.
        automaticallyImplyLeading: false,
      ),
      body: Consumer<LocationTrackerController>(
        builder: (context, controller, child) {
          final Position? position = controller.currentPosition;
          final bool isTracking = controller.isTracking;

          // Zeigt eine Hilfestellung an, falls das Tracking inaktiv ist
          if (!isTracking || position == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  'Starte das GPS-Tracking auf dem vorherigen Screen, um hier Live-Daten zu sehen.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Wandelt die Geschwindigkeit von m/s in km/h um
          final speedInKmh = (position.speed * 3.6).toStringAsFixed(1);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            // ListView verhindert einen Pixel-Overflow auf kleinen Bildschirmen
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 20),
                _buildGpsDataRow(
                  context: context,
                  icon: Icons.location_on_outlined,
                  label: 'Latitude',
                  value: position.latitude.toStringAsFixed(6),
                ),
                const Divider(),
                _buildGpsDataRow(
                  context: context,
                  icon: Icons.location_on_outlined,
                  label: 'Longitude',
                  value: position.longitude.toStringAsFixed(6),
                ),
                const Divider(),
                _buildGpsDataRow(
                  context: context,
                  icon: Icons.speed,
                  label: 'Geschwindigkeit',
                  value: '$speedInKmh km/h',
                ),
                const Divider(),
                _buildGpsDataRow(
                  context: context,
                  icon: Icons.arrow_upward,
                  label: 'Höhe',
                  value: '${position.altitude.toStringAsFixed(1)} m',
                ),
                const Divider(),
                _buildGpsDataRow(
                  context: context,
                  icon: Icons.gps_fixed,
                  label: 'Genauigkeit',
                  value: '${position.accuracy.toStringAsFixed(1)} m',
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    controller.statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hilfs-Widget für eine konsistente Darstellung der Datenzeilen
  Widget _buildGpsDataRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).hintColor, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}