// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mit dem Provider auf den Controller zugreifen
    final settingsController = context.watch<SettingsController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking-Einstellungen'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // --- Beispiel für eine Einstellung (Tracking-Intervall) ---
          Text(
            'GPS-Abfrageintervall', 
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${settingsController.trackingInterval} Sekunden',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: settingsController.trackingInterval.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '${settingsController.trackingInterval.round()}s',
            onChanged: (value) {
              // Wichtig: 'listen: false' im onChanged, da wir hier nur eine Aktion auslösen
              Provider.of<SettingsController>(context, listen: false)
                  .updateTrackingInterval(value.toInt());
            },
          ),
          const Divider(),

          // --- FÜGEN SIE HIER WEITERE SLIDER/SCHALTER FÜR DIE ANDEREN EINSTELLUNGEN EIN ---
          // (Genauigkeitspuffer, Zeitfilter an/aus, Zeitfilter-Wert)
        ],
      ),
    );
  }
}