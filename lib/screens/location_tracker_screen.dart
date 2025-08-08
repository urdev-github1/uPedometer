// lib/screens/location_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// NEU: Import für permission_handler hinzufügen, um openAppSettings() zu nutzen
import 'package:permission_handler/permission_handler.dart';
import '../controllers/location_tracker_controller.dart';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Zustand erhalten

  Future<void> _showResetConfirmationDialog(BuildContext context) async {
    final controller = Provider.of<LocationTrackerController>(context, listen: false);
    final bool? confirmReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).dialogTheme.backgroundColor,
          title: Text('Tracking zurücksetzen?', style: Theme.of(dialogContext).textTheme.titleLarge),
          content: Text(
            'Möchtest du die aufgezeichnete Distanz, Zeit und Adresse wirklich löschen?',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen', style: TextStyle(color: Theme.of(dialogContext).textTheme.bodyMedium?.color)),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(204)),
              child: const Text('Zurücksetzen', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmReset == true) {
      // Da der context hier nicht verwendet wird, ist kein mounted-Check nach dem await nötig.
      controller.resetTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS-Tracking'),
        centerTitle: true, 
        automaticallyImplyLeading: false, 
      ),
      body: Consumer<LocationTrackerController>(
        builder: (context, controller, child) {
          String formatTime(DateTime? time) {
            if (time == null) return '--:--';
            return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          }

          final roundedDistance = controller.totalDistanceInKm.toStringAsFixed(2);
          final textTheme = Theme.of(context).textTheme;

          return Column(
            children: <Widget>[
              // --- FESTER OBERER TEIL ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roundedDistance,
                      style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: textTheme.bodyLarge?.color),
                    ),
                    Text('Kilometer', style: TextStyle(fontSize: 24, color: textTheme.bodyMedium?.color)),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTimeInfoCard(context: context, label: 'Startzeit', value: formatTime(controller.startTime)),
                        _buildTimeInfoCard(context: context, label: 'Dauer', value: controller.trackingDurationFormatted, isHighlighted: true),
                        _buildTimeInfoCard(context: context, label: 'Stoppzeit', value: formatTime(controller.stopTime)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          // =============================================================== //
                          // --- ANPASSUNG START: Logik für Berechtigungsprüfung ---         //
                          // =============================================================== //
                          onPressed: controller.isTracking
                              ? null
                              : () async { // Den onPressed-Callback als async markieren
                                  final result = await controller.startTracking();

                                  // HINWEIS: Es wird `context.mounted` anstelle von `this.mounted` (vom State) verwendet.
                                  // Dies stellt sicher, dass der spezifische BuildContext des Consumers zum Zeitpunkt
                                  // des Dialogaufrufs nach dem 'await' noch gültig (mounted) ist.
                                  if (result == TrackingStartResult.notificationDenied && context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        final dialogTheme = Theme.of(dialogContext);
                                        return AlertDialog(
                                          backgroundColor: dialogTheme.dialogTheme.backgroundColor,
                                          title: Text('Benachrichtigung erforderlich', style: dialogTheme.textTheme.titleLarge),
                                          content: Text(
                                            'Um die Route im Hintergrund aufzuzeichnen, benötigt die App die Erlaubnis, Benachrichtigungen zu senden. Bitte aktivieren Sie diese in den Einstellungen.',
                                            style: dialogTheme.textTheme.bodyMedium,
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('Abbrechen', style: TextStyle(color: dialogTheme.textTheme.bodyMedium?.color)),
                                              onPressed: () => Navigator.of(dialogContext).pop(),
                                            ),
                                            TextButton(
                                              child: const Text('Einstellungen öffnen'),
                                              onPressed: () {
                                                // Öffnet direkt die App-Einstellungen
                                                openAppSettings();
                                                Navigator.of(dialogContext).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      }
                                    );
                                  }
                                },
                          // =============================================================== //
                          // --- ANPASSUNG ENDE ---                                          //
                          // =============================================================== //
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Stopp', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: controller.isTracking ? controller.stopTracking : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // --- CONTAINER FÜR DEN ADRESSBLOCK ---
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 1.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aktuelle Position:',
                            style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            alignment: Alignment.centerLeft, // <<< ÄNDERUNG HIER
                            child: Builder(
                              builder: (context) {
                                if (controller.isFetchingAddress) {
                                  return const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.0)
                                  );
                                }
                                
                                if (controller.address != null) {
                                  return Text(
                                    controller.address!,
                                    style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                                    textAlign: TextAlign.start,
                                    softWrap: true,
                                  );
                                } else {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start, // <<< ÄNDERUNG HIER
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Tippe ',
                                        style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                                      ),
                                      Icon(
                                        Icons.pin_drop_outlined,
                                        color: textTheme.bodyLarge?.color,
                                        size: 20.0,
                                      ),
                                      Text(
                                        ' um die Adresse zu laden.',
                                        style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: Consumer<LocationTrackerController>(
          builder: (context, controller, child) {
            final iconColor = Theme.of(context).textTheme.bodyMedium?.color;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.pin_drop_outlined, color: iconColor),
                  iconSize: 32.0, 
                  tooltip: 'Adresse erfassen',
                  onPressed: controller.isFetchingAddress ? null : controller.fetchAddress,
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: iconColor),
                  iconSize: 32.0, 
                  tooltip: 'Tracking zurücksetzen',
                  onPressed: controller.isTracking ? null : () => _showResetConfirmationDialog(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeInfoCard({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 26 : 24,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Theme.of(context).hintColor : textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}