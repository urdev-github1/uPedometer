// lib/screens/location_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                          onPressed: controller.isTracking ? null : controller.startTracking,
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
              
              // =============================================================== //
              // --- ANPASSUNG START: Padding für Adressblock geändert ---       //
              // =============================================================== //
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  // Das Padding wurde von 'symmetric' zu 'fromLTRB' geändert,
                  // um den linken Abstand zu vergrößern (hier auf 44).
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(44.0, 20.0, 20.0, 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktuelle Position:',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(minHeight: 48), // Höhe für zwei Textzeilen
                          alignment: Alignment.centerLeft,
                          child: Builder(
                            builder: (context) {
                              if (controller.isFetchingAddress) {
                                return const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.0)
                                );
                              }
                              return Text(
                                controller.address ?? '', // Zeigt einen leeren String, wenn keine Adresse da ist.
                                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                                softWrap: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // =============================================================== //
              // --- ANPASSUNG ENDE ---                                          //
              // =============================================================== //
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