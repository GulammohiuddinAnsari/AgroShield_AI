import 'package:flutter/material.dart';
import 'scanner_screen.dart';

void main() {
  runApp(const AgroShieldApp());
}

class AgroShieldApp extends StatelessWidget {
  const AgroShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroShield AI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const ScannerScreen(), // Routes to the new screen
    );
  }
}