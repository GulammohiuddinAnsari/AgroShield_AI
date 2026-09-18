import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'result_screen.dart'; // Import the new result screen

// ------------------------------------------------------------------
// TOP-LEVEL FUNCTION
// ------------------------------------------------------------------
List<List<List<List<double>>>>? processImagePixels(Uint8List imageBytes) {
  img.Image? decodedImage = img.decodeImage(imageBytes);
  if (decodedImage == null) return null;

  img.Image resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

  return List.generate(1, (b) => 
                List.generate(224, (y) => 
                  List.generate(224, (x) {
                    final pixel = resizedImage.getPixel(x, y);
                    return [
                      pixel.r / 255.0,
                      pixel.g / 255.0,
                      pixel.b / 255.0
                    ];
                  })));
}
// ------------------------------------------------------------------

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _isProcessing = false; 
  String _statusMessage = "Ready to scan. No internet required.";

  @override
  void initState() {
    super.initState();
    _loadOfflineModel();
  }

  Future<void> _loadOfflineModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/offline_crop_model.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _captureAndAnalyze() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;
    
    File capturedImage = File(pickedFile.path);

    setState(() {
      _isProcessing = true;
      _statusMessage = "Analyzing leaf offline...";
    });

    try {
      final Uint8List imageBytes = await capturedImage.readAsBytes();
      final input = await Isolate.run(() => processImagePixels(imageBytes));

      if (input == null) throw Exception("Failed to decode image");

      var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));
      _interpreter.run(input, output);

      final confidences = output[0];
      double maxScore = confidences[0];
      int maxIndex = 0;
      
      for (int i = 1; i < confidences.length; i++) {
        if (confidences[i] > maxScore) {
          maxScore = confidences[i];
          maxIndex = i;
        }
      }

      String diseaseName = _labels.isNotEmpty ? _labels[maxIndex] : "Unknown";

      setState(() {
        _isProcessing = false;
        _statusMessage = "Ready to scan.";
      });

      // NAVIGATE TO RESULT SCREEN (Just like React Router!)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              image: capturedImage,
              diseaseName: diseaseName,
              confidence: maxScore,
            ),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroShield AI'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.energy_savings_leaf, size: 140, color: Colors.green.shade300),
              const SizedBox(height: 40),
              _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.green)
                  : Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureAndAnalyze,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text("Scan Leaf", style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}