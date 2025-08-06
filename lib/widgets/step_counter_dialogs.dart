// lib/widgets/step_counter_dialogs.dart

import 'package:flutter/material.dart';
import 'package:upedometer/controllers/step_counter_controller.dart';
// NEU: Importieren Sie Ihren generischen Dialog.
import 'package:upedometer/widgets/generic_dialog.dart'; 

/// Zeigt den Dialog zum Zurücksetzen des Zählers an und führt die Aktion nach Bestätigung aus.
Future<void> showResetConfirmationDialog(BuildContext context, StepCounterController controller) async {
  // OPTIMIERT: Der gesamte showDialog-Code wird durch einen einzigen Funktionsaufruf ersetzt.
  final bool? confirmReset = await showConfirmationDialog(
    context: context,
    title: 'Zähler zurücksetzen?',
    content: 'Möchtest du deinen Fortschritt wirklich auf 0 zurücksetzen?',
    confirmText: 'Zurücksetzen', // Spezifischer Text für den Button
  );

  // Die Logik bleibt gleich.
  if (confirmReset == true) {
    controller.resetCounter();
  }
}

/// Zeigt den Dialog zur Anpassung der Schrittlänge an. (Dieser Teil bleibt unverändert)
void showStepLengthDialog(BuildContext context, StepCounterController controller) {
  showDialog(
    context: context,
    builder: (dialogContext) => _StepLengthDialogContent(controller: controller),
  );
}

class _StepLengthDialogContent extends StatefulWidget {
  // ... (Restlicher Code bleibt unverändert)
  final StepCounterController controller;
  const _StepLengthDialogContent({required this.controller});

  @override
  State<_StepLengthDialogContent> createState() => _StepLengthDialogContentState();
}

class _StepLengthDialogContentState extends State<_StepLengthDialogContent> {
  late double _currentStepLengthCm;

  @override
  void initState() {
    super.initState();
    _currentStepLengthCm = widget.controller.stepLengthInCm;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      title: Text('Schrittlänge anpassen', style: Theme.of(context).textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentStepLengthCm.toStringAsFixed(0)} cm',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: 24,
                ),
          ),
          Slider(
            value: _currentStepLengthCm,
            min: 30,
            max: 100,
            divisions: 70,
            label: '${_currentStepLengthCm.round()} cm',
            onChanged: (double value) {
              setState(() {
                _currentStepLengthCm = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Abbrechen', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Speichern'),
          onPressed: () {
            widget.controller.updateStepLength(_currentStepLengthCm);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}