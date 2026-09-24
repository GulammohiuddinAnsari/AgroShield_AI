import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'result_screen.dart';
import 'history_screen.dart';
import 'localization_helper.dart';

/// Background Isolate: Green Pixel Validation & TFLite Preprocessing
Future<Map<String, dynamic>> processAndValidateImage(Uint8List bytes) async {
  return Isolate.run(() {
    final img.Image? original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception('Could not decode image.');
    }

    // 1. Green Pixel Filter to prevent non-leaf false positives
    int greenPixels = 0;
    int sampledPixels = 0;

    for (int y = 0; y < original.height; y += 4) {
      for (int x = 0; x < original.width; x += 4) {
        final pixel = original.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        sampledPixels++;
        if (g > r + 10 && g > b + 10) {
          greenPixels++;
        }
      }
    }

    double greenRatio = greenPixels / sampledPixels;
    if (greenRatio < 0.12) {
      return {'isValidLeaf': false, 'inputTensor': null};
    }

    // 2. Resize & Normalize for MobileNetV2
    final img.Image resized = img.copyResize(original, width: 224, height: 224);

    final inputTensor = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    return {'isValidLeaf': true, 'inputTensor': inputTensor};
  });
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _modelLoaded = false;
  bool _analyzing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final Interpreter interpreter = await Interpreter.fromAsset('assets/offline_crop_model.tflite');
      final String labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      final List<String> labels = labelsData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      _interpreter = interpreter;
      _labels = labels;

      if (mounted) setState(() => _modelLoaded = true);
    } catch (e) {
      if (mounted) setState(() => _modelLoaded = false);
    }
  }

  Future<void> _selectImage(ImageSource source) async {
    if (_analyzing) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1280, maxHeight: 1280);
      if (pickedFile == null) return;
      setState(() => _selectedImage = File(pickedFile.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not select image: $e')));
    }
  }

  Future<void> _detectPlant() async {
    if (_selectedImage == null || !_modelLoaded || _interpreter == null || _analyzing) return;

    try {
      setState(() => _analyzing = true);

      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      final validationResult = await processAndValidateImage(imageBytes);
      final bool isValidLeaf = validationResult['isValidLeaf'];

      if (!isValidLeaf) {
        if (!mounted) return;
        setState(() => _analyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ This does not look like a plant leaf! Please upload a clear photo of a crop leaf.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final input = validationResult['inputTensor'];
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;

      final List<List<double>> output = List.generate(
        outputShape[0],
        (_) => List<double>.filled(outputShape[1], 0.0),
      );

      _interpreter!.run(input, output);

      int bestIndex = 0;
      double bestScore = 0.0;

      if (outputShape[1] == 1) {
        bestIndex = output[0][0].round().clamp(0, _labels.length - 1);
        bestScore = 1.0;
      } else {
        final List<double> scores = output[0];
        bestScore = scores[0];
        for (int i = 1; i < scores.length; i++) {
          if (scores[i] > bestScore) {
            bestScore = scores[i];
            bestIndex = i;
          }
        }
      }

      final String prediction = _labels[bestIndex];

      if (!mounted) return;
      setState(() => _analyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: _selectedImage!,
            diseaseName: prediction,
            confidence: bestScore,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _resetScan() {
    if (_analyzing) return;
    setState(() => _selectedImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _selectedImage != null;
    final localization = LocalizationHelper.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        title: Text(localization.translate('scanner_title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
            tooltip: 'Scan History',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Developer Note / Context Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.security_rounded, color: Colors.green.shade800, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Offline Neural Engine', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1B4D3E))),
                          SizedBox(height: 3),
                          Text(
                            'Powered by an edge TFLite model. Diagnoses leaf anomalies locally on your device without uploading data to external cloud servers.',
                            style: TextStyle(color: Colors.black54, fontSize: 11.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Image Preview Container
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF1B4D3E).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: hasImage
                    ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                            child: Icon(Icons.add_a_photo_rounded, size: 48, color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 16),
                          Text(localization.translate('no_image'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B4D3E))),
                          const SizedBox(height: 6),
                          Text(localization.translate('image_hint'), style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!hasImage) ...[
                ElevatedButton.icon(
                  onPressed: _modelLoaded ? () => _selectImage(ImageSource.camera) : null,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(localization.translate('capture_photo'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _modelLoaded ? () => _selectImage(ImageSource.gallery) : null,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(localization.translate('upload_gallery'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B4D3E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],

              if (hasImage && !_analyzing) ...[
                ElevatedButton.icon(
                  onPressed: _detectPlant,
                  icon: const Icon(Icons.bolt_rounded),
                  label: Text(localization.translate('run_diagnosis'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(localization.translate('clear_image'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],

              if (_analyzing) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF1B4D3E), strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(localization.translate('analyzing'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(localization.translate('running_ai'), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Status Chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _modelLoaded ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _modelLoaded ? Colors.green.shade200 : Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _modelLoaded ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: 16,
                        color: _modelLoaded ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _modelLoaded ? localization.translate('model_ready') : localization.translate('loading_model'),
                        style: TextStyle(
                          color: _modelLoaded ? Colors.green.shade800 : Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}