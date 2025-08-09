// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upedometer/controllers/location_tracker_controller.dart';
import 'package:upedometer/controllers/step_counter_controller.dart';
import 'package:upedometer/notifiers/theme_notifier.dart';
import 'package:upedometer/utils/app_theme.dart';
import 'package:upedometer/screens/main_screen.dart'; 
import 'package:upedometer/controllers/settings_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => StepCounterController()..init()),
        ChangeNotifierProvider(create: (_) => LocationTrackerController()..init()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'uPedometer',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const MainScreen(),
    );
  }
}