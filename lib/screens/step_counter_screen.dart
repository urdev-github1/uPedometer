// lib/screens/step_counter_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upedometer/notifiers/theme_notifier.dart';
import 'package:upedometer/controllers/step_counter_controller.dart';
import 'package:upedometer/widgets/progress_circle.dart';
import 'package:upedometer/widgets/info_card.dart';
import 'package:upedometer/widgets/step_counter_dialogs.dart';
import '../utils/constants.dart';

class StepCounterScreen extends StatefulWidget {
  final PageController pageController;

  const StepCounterScreen({super.key, required this.pageController});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    final stepController = context.watch<StepCounterController>();
    final themeNotifier = context.watch<ThemeNotifier>();

    return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(top: 32.0), // Abstand von oben
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            '10000 Schritte',
            style: Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle(fontSize: 25, color: Colors.white),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
    ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: ProgressCircle(steps: stepController.sessionSteps, goal: dailyStepGoal),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InfoCard(icon: Icons.directions_walk, value: '${stepController.sessionSteps}', label: 'Schritte'),
                      InfoCard(icon: Icons.map, value: '${stepController.distanceInKm} km', label: 'Distanz'),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: _buildBottomAppBar(context, stepController, themeNotifier),
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context, StepCounterController stepController, ThemeNotifier themeNotifier) {
    final iconColor = Theme.of(context).textTheme.bodyMedium?.color;
    const double iconSize = 32.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.tune, color: iconColor),
          iconSize: iconSize,
          tooltip: 'Schrittlänge anpassen',
          onPressed: () => showStepLengthDialog(context, stepController),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: iconColor),
          iconSize: iconSize,
          tooltip: 'Zähler zurücksetzen',
          // Dieser Aufruf funktioniert jetzt mit der korrigierten Logik im Hintergrund.
          onPressed: () => showResetConfirmationDialog(context, stepController),
        ),
        IconButton(
          icon: Icon(
            themeNotifier.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            color: iconColor
          ),
          iconSize: iconSize,
          tooltip: 'Theme wechseln',
          onPressed: () => themeNotifier.toggleTheme(),
        ),
      ],
    );
  }
}