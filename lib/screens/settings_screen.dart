// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mit Provider auf den Controller zugreifen und bei Änderungen neu bauen
    final settingsController = context.watch<SettingsController>();
    final textTheme = Theme.of(context).textTheme;
    
    // =============================================================== //
    // --- ANPASSUNG: Theme-Helligkeit für dynamische Farben ---       //
    // =============================================================== //
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking-Einstellungen'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: <Widget>[
          // --- EINSTELLUNG 1: GPS-Abfrageintervall ---
          Text('GPS-Abfrageintervall', style: textTheme.titleLarge),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              'Fordert alle ${settingsController.trackingInterval} Sekunden eine neue Position vom System an. Kürzere Intervalle können den Akkuverbrauch erhöhen.',
              style: textTheme.bodyMedium,
            ),
          ),
          Slider(
            value: settingsController.trackingInterval.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '${settingsController.trackingInterval.round()}s',
            onChanged: (value) {
              context.read<SettingsController>().updateTrackingInterval(value.toInt());
            },
          ),
          const Divider(height: 40),

          // --- EINSTELLUNG 2: Genauigkeitspuffer ---
          Text('Genauigkeitspuffer', style: textTheme.titleLarge),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              'Ein neuer Punkt wird nur gespeichert, wenn die Distanz zum letzten Punkt größer ist als (Aktuelle GPS-Genauigkeit + ${settingsController.accuracyBuffer.toStringAsFixed(1)}m).',
              style: textTheme.bodyMedium,
            ),
          ),
          Slider(
            value: settingsController.accuracyBuffer,
            min: 0.0,
            max: 10.0,
            divisions: 20,
            label: '${settingsController.accuracyBuffer.toStringAsFixed(1)}m',
            onChanged: (value) {
              context.read<SettingsController>().updateAccuracyBuffer(value);
            },
          ),
          const Divider(height: 40),

          // --- EINSTELLUNG 3 & 4: Zeitfilter ---
          Text('Zusätzlicher Zeitfilter', style: textTheme.titleLarge),
          SwitchListTile(
            title: Text('Zeitfilter aktivieren', style: textTheme.bodyLarge),
            subtitle: Text('Erzwingt eine Mindestzeit zwischen zwei gespeicherten Punkten.', style: textTheme.bodyMedium),
            value: settingsController.isTimeFilterEnabled,
            onChanged: (bool value) {
              context.read<SettingsController>().updateTimeFilterEnabled(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          // Dieser Teil wird nur angezeigt, wenn der Filter aktiv ist
          if (settingsController.isTimeFilterEnabled) ...[
            const SizedBox(height: 10),
            Text(
              'Mindestzeit zwischen Punkten: ${settingsController.timeFilterValue} Sekunden',
              style: textTheme.bodyMedium,
            ),
            Slider(
              value: settingsController.timeFilterValue.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '${settingsController.timeFilterValue}s',
              onChanged: (value) {
                context.read<SettingsController>().updateTimeFilterValue(value.toInt());
              },
            ),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                // Die Hintergrundfarbe kann auch angepasst werden, falls gewünscht
                color: isDarkMode ? Colors.orange.withOpacity(0.25) : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Achtung: Ein hoher Zeitfilter kann dazu führen, dass schnelle Kurven "abgeschnitten" und ungenau aufgezeichnet werden.',
                // =============================================================== //
                // --- ANPASSUNG: Dynamische Textfarbe für besseren Kontrast ---   //
                // =============================================================== //
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8),
                  fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}