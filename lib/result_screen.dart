import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String diseaseName;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.image,
    required this.diseaseName,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image, height: 300, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 30),
              const Text(
                "Detected Disease:",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                diseaseName,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              // We will add the SQLite Remedy Data here next!
            ],
          ),
        ),
      ),
    );
  }
}