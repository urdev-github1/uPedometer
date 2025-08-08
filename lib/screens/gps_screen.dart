// lib/screens/gps_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/location_tracker_controller.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = context.watch<LocationTrackerController>();
    final position = controller.currentPosition;
    final isTracking = controller.isTracking;
    final bool canShare = isTracking && position != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS-Status'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Koordinaten teilen',
            // =============================================================== //
            // --- ANPASSUNG START: Robusterer "onPressed"-Callback ---        //
            // =============================================================== //
            onPressed: !canShare
                ? null
                : () async { // Callback als async markieren
                    // Schritt 1: Überprüfen, ob das Widget noch im Widget-Baum ist.
                    if (!mounted) return;

                    // Schritt 2: Debug-Ausgabe, um zu bestätigen, dass die Funktion aufgerufen wird.
                    debugPrint("Share button pressed. Attempting to share coordinates.");

                    try {
                      final lat = position!.latitude.toStringAsFixed(6);
                      final lon = position.longitude.toStringAsFixed(6);

                      final String shareText =
                          'Hier sind meine aktuellen GPS-Koordinaten:\n\n'
                          'Latitude: $lat\n'
                          'Longitude: $lon\n\n'
                          'Auf der Karte ansehen:\n'
                          'https://www.google.com/maps/search/?api=1&query=$lat,$lon\n\n'
                          'Standard Geo-Format:\n'
                          'geo:$lat,$lon';

                      // Schritt 3: Führe die Teilen-Aktion aus.
                      await Share.share(
                        shareText,
                        subject: 'Meine aktuelle GPS-Position',
                      );
                    } catch (e) {
                      // Schritt 4: Fehler abfangen und dem Benutzer eine Rückmeldung geben.
                      debugPrint("Error sharing coordinates: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Teilen ist fehlgeschlagen.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            // =============================================================== //
            // --- ENDE DER ANPASSUNG ---                                      //
            // =============================================================== //
          ),
        ],
      ),
      body: _buildBodyContent(context, isTracking, position, controller.statusMessage),
    );
  }

  Widget _buildBodyContent(BuildContext context, bool isTracking, Position? position, String statusMessage) {
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

    final speedInKmh = (position.speed * 3.6).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 20),
          _buildGpsDataRow(context: context, icon: Icons.location_on_outlined, label: 'Latitude', value: position.latitude.toStringAsFixed(6)),
          const Divider(),
          _buildGpsDataRow(context: context, icon: Icons.location_on_outlined, label: 'Longitude', value: position.longitude.toStringAsFixed(6)),
          const Divider(),
          _buildGpsDataRow(context: context, icon: Icons.speed, label: 'Geschwindigkeit', value: '$speedInKmh km/h'),
          const Divider(),
          _buildGpsDataRow(context: context, icon: Icons.arrow_upward, label: 'Höhe', value: '${position.altitude.toStringAsFixed(1)} m'),
          const Divider(),
          _buildGpsDataRow(context: context, icon: Icons.gps_fixed, label: 'Genauigkeit', value: '${position.accuracy.toStringAsFixed(1)} m'),
          const SizedBox(height: 40),
          Center(
            child: Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsDataRow({required BuildContext context, required IconData icon, required String label, required String value}) {
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}