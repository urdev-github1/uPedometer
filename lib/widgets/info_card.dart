// lib/widgets/info_card.dart

import 'package:flutter/material.dart';

//
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const InfoCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        // REFAKTOR: Farbe vom Theme verwenden
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [ // Optional: Fügt im hellen Theme einen leichten Schatten hinzu
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.grey.withAlpha(51), // Approximately 0.2 opacity
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        children: [
          // REFAKTOR: Akzentfarbe vom Theme verwenden
          Icon(icon, color: Theme.of(context).hintColor, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // REFAKTOR: Farbe vom Theme verwenden
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              // REFAKTOR: Farbe vom Theme verwenden
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}