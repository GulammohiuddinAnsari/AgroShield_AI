import 'package:flutter/material.dart';
import 'home_dashboard.dart';
import 'localization_helper.dart';

void main() {
  runApp(const AgroShieldApp());
}

class AgroShieldApp extends StatelessWidget {
  const AgroShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder listens to language changes and rebuilds the whole app globally
    return ListenableBuilder(
      listenable: LocalizationHelper.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'AgroShield AI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          home: const HomeDashboard(),
        );
      },
    );
  }
}