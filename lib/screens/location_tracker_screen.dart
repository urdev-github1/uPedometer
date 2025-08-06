// lib/screens/location_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/location_tracker_controller.dart';
import 'package:upedometer/widgets/generic_dialog.dart';

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

    // OPTIMIERT: Ersetzen Sie den langen Dialog-Code durch den sauberen Funktionsaufruf.
    final bool? confirmReset = await showConfirmationDialog(
      context: context,
      title: 'Tracking zurücksetzen?',
      content: 'Möchtest du die aufgezeichnete Distanz, Zeit und Adresse wirklich löschen?',
      confirmText: 'Zurücksetzen',
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

          // GEÄNDERT: Haupt-Layout ist jetzt eine Column, um den Screen aufzuteilen.
          return Column(
            children: <Widget>[
              // --- FESTER OBERER TEIL ---
              // Dieser Teil hat eine feste Größe und wird nicht verschoben.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roundedDistance,
                      style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    Text('Kilometer', style: TextStyle(fontSize: 24, color: Theme.of(context).textTheme.bodyMedium?.color)),
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

              // --- FLEXIBLER UNTERER TEIL ---
              // Dieser Teil füllt den restlichen verfügbaren Platz.
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter, // Richtet die Adresse oben in diesem Bereich aus.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: _buildAddressDisplay(context, controller),
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

  Widget _buildAddressDisplay(BuildContext context, LocationTrackerController controller) {
    if (controller.isFetchingAddress) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (controller.address != null) {
      return _buildAddressRow(
        context: context,
        icon: Icons.location_on,
        label: 'Aktuelle Position:',
        address: controller.address!,
      );
    }
    
    return const SizedBox.shrink(); // Leeres Widget, wenn keine Adresse da ist.
  }

  Widget _buildAddressRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String address,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: textTheme.bodyMedium?.color?.withAlpha(200), size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                address,
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
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