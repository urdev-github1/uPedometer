// lib/widgets/progress_circle.dart

import 'package:flutter/material.dart';

class ProgressCircle extends StatelessWidget {
  final int steps;
  final int goal;

  const ProgressCircle({super.key, required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    double percentage = (goal > 0) ? (steps / goal) : 0.0;
    if (percentage > 1.0) percentage = 1.0;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0, 
            strokeWidth: 15,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.withAlpha(51)
                : Colors.grey.withAlpha(51), // Gleiche Transparenz für beide Themes
          ),
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: 15,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).hintColor),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$steps',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                // ANPASSUNG 3: Text "/ 10000 Schritte" wurde entfernt.
              ],
            ),
          ),
        ],
      ),
    );
  }
}