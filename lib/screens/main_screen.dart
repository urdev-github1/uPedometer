// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import '../screens/step_counter_screen.dart';
import '../screens/location_tracker_screen.dart';
import '../screens/gps_screen.dart'; 
import '../screens/map_screen.dart'; // NEU: Importieren

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: <Widget>[
          // Seite 1: StepCounterScreen
          StepCounterScreen(pageController: _pageController),
          
          // Seite 2: LocationTrackerScreen
          const LocationTrackerScreen(),

          // Seite 3: GpsScreen
          const GpsScreen(),

          // NEU: Seite 4: MapScreen
          MapScreen(pageController: _pageController),
        ],
      ),
    );
  }
}