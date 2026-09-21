import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// ------------------------------------------------------------
/// IMAGE PREPROCESSING
/// ------------------------------------------------------------
Future<List<List<List<List<double>>>>> processImageInBackground(
    Uint8List bytes) async {
  return Isolate.run(() {
    final img.Image? original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception('Could not decode image.');
    }

    final img.Image resized = img.copyResize(
      original,
      width: 224,
      height: 224,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);

            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  });
}

/// ------------------------------------------------------------
/// SCANNER SCREEN
/// ------------------------------------------------------------

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

  String? _prediction;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  /// ----------------------------------------------------------
  /// LOAD TFLITE MODEL
  /// ----------------------------------------------------------

  Future<void> _loadModel() async {
    try {
      debugPrint('==============================');
      debugPrint('LOADING AI MODEL');

      final Interpreter interpreter =
          await Interpreter.fromAsset(
        'assets/offline_crop_model.tflite',
      );

      final String labelsData =
          await DefaultAssetBundle.of(context).loadString(
        'assets/labels.txt',
      );

      final List<String> labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);

      debugPrint('MODEL LOADED');
      debugPrint('Input shape: ${inputTensor.shape}');
      debugPrint('Input type: ${inputTensor.type}');
      debugPrint('Output shape: ${outputTensor.shape}');
      debugPrint('Output type: ${outputTensor.type}');
      debugPrint('Labels: $labels');

      _interpreter = interpreter;
      _labels = labels;

      if (mounted) {
        setState(() {
          _modelLoaded = true;
        });
      }

      debugPrint('AI MODEL READY');
      debugPrint('==============================');
    } catch (e, stackTrace) {
      debugPrint('MODEL LOAD ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _modelLoaded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Model loading failed: $e',
          ),
        ),
      );
    }
  }

  /// ----------------------------------------------------------
  /// SELECT IMAGE
  /// ----------------------------------------------------------

  Future<void> _selectImage(ImageSource source) async {
    if (_analyzing) return;

    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (pickedFile == null) {
        debugPrint('IMAGE SELECTION CANCELLED');
        return;
      }

      final File imageFile = File(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _selectedImage = imageFile;
        _prediction = null;
        _confidence = null;
      });

      debugPrint('IMAGE SELECTED: ${pickedFile.path}');
    } catch (e, stackTrace) {
      debugPrint('IMAGE SELECTION ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: $e'),
        ),
      );
    }
  }

  /// ----------------------------------------------------------
  /// DETECT PLANT
  /// ----------------------------------------------------------

  Future<void> _detectPlant() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture an image first.'),
        ),
      );
      return;
    }

    if (!_modelLoaded || _interpreter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model is still loading. Please wait.'),
        ),
      );
      return;
    }

    if (_analyzing) return;

    try {
      if (!mounted) return;

      setState(() {
        _analyzing = true;
        _prediction = null;
        _confidence = null;
      });

      debugPrint('==============================');
      debugPrint('STARTING PLANT ANALYSIS');

      final Uint8List imageBytes =
          await _selectedImage!.readAsBytes();

      debugPrint('IMAGE READ: ${imageBytes.length} bytes');

      final List<List<List<List<double>>>> input =
          await processImageInBackground(imageBytes);

      debugPrint('IMAGE PROCESSING COMPLETE');

      /// --------------------------------------------------------
      /// CHECK MODEL OUTPUT SHAPE DYNAMICALLY
      /// --------------------------------------------------------
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape; // Handles [1, 1] or [1, 6]

      debugPrint('INPUT SHAPE: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('OUTPUT SHAPE: $outputShape');

      // Dynamically generate the buffer matching the model output shape
      final List<List<double>> output = List.generate(
        outputShape[0],
        (_) => List<double>.filled(outputShape[1], 0.0),
      );

      debugPrint('STARTING MODEL INFERENCE');

      _interpreter!.run(input, output);

      debugPrint('MODEL OUTPUT: ${output[0]}');

      /// --------------------------------------------------------
      /// PARSE RESULTS BASED ON SHAPE
      /// --------------------------------------------------------
      int bestIndex = 0;
      double bestScore = 1.0;

      if (outputShape[1] == 1) {
        // Model outputs a single class index directly
        bestIndex = output[0][0].round().clamp(0, _labels.length - 1);
        bestScore = 1.0; 
      } else {
        // Model outputs probability distribution array
        final List<double> scores = output[0];
        bestScore = scores[0];
        for (int i = 1; i < scores.length; i++) {
          if (scores[i] > bestScore) {
            bestScore = scores[i];
            bestIndex = i;
          }
        }
      }

      if (bestScore.isNaN || bestScore.isInfinite) {
        throw Exception('Model returned an invalid confidence value.');
      }

      final String prediction = _labels[bestIndex];

      debugPrint('BEST INDEX: $bestIndex');
      debugPrint('PREDICTION: $prediction');
      debugPrint('MODEL SCORE: $bestScore');
      debugPrint('ANALYSIS COMPLETE');
      debugPrint('==============================');

      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _prediction = prediction;
        _confidence = bestScore;
      });
    } catch (e, stackTrace) {
      debugPrint('==============================');
      debugPrint('ANALYSIS ERROR: $e');
      debugPrint('$stackTrace');
      debugPrint('==============================');

      if (!mounted) return;

      setState(() {
        _analyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
        ),
      );
    }
  }

  void _resetScan() {
    if (_analyzing) return;

    setState(() {
      _selectedImage = null;
      _prediction = null;
      _confidence = null;
    });
  }

  String _getResultTitle(String prediction) {
    final String lower = prediction.toLowerCase();

    if (lower.contains('healthy')) {
      return 'Healthy Plant';
    }
    if (lower.contains('early')) {
      return 'Early Blight';
    }
    if (lower.contains('late')) {
      return 'Late Blight';
    }

    return prediction;
  }

  String _getPlantName(String prediction) {
    final String lower = prediction.toLowerCase();

    if (lower.contains('potato')) {
      return 'Potato';
    }
    if (lower.contains('tomato')) {
      return 'Tomato';
    }

    return 'Plant';
  }

  String _getRecommendation(String prediction) {
    final String lower = prediction.toLowerCase();

    if (lower.contains('healthy')) {
      return 'The plant leaf appears healthy. Continue regular monitoring, balanced watering, proper nutrition, and good crop care.';
    }
    if (lower.contains('early')) {
      return 'Early blight was detected. Remove badly affected leaves, avoid prolonged leaf wetness, provide good airflow, and follow local disease-management guidelines.';
    }
    if (lower.contains('late')) {
      return 'Late blight was detected. Remove severely affected plant material, reduce prolonged leaf wetness, improve airflow, and follow local disease-management guidelines.';
    }

    return 'Monitor the plant closely and follow appropriate crop-care practices.';
  }

  Widget _buildResultCard() {
    if (_prediction == null || _confidence == null) {
      return const SizedBox.shrink();
    }

    final String prediction = _prediction!;
    final String resultTitle = _getResultTitle(prediction);
    final String plantName = _getPlantName(prediction);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Analysis Result',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            resultTitle,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plant: $plantName',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prediction: $prediction',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'AI Confidence',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _confidence!,
            minHeight: 9,
            borderRadius: BorderRadius.circular(10),
            color: Colors.green,
            backgroundColor: Colors.green.shade100,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_confidence! * 100).toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '💊 Recommendation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getRecommendation(prediction),
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _selectedImage != null;
    final bool hasResult = _prediction != null && _confidence != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text(
          'AgroShield AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Smart Crop Health Scanner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Capture or upload a plant leaf to check its condition.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1.5,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 80,
                            color: Colors.green,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              if (!hasImage) ...[
                ElevatedButton.icon(
                  onPressed: _modelLoaded
                      ? () => _selectImage(ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Click Image',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _modelLoaded
                      ? () => _selectImage(ImageSource.gallery)
                      : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text(
                    'Upload Image',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              if (hasImage && !hasResult && !_analyzing) ...[
                const SizedBox(height: 5),
                ElevatedButton.icon(
                  onPressed: _detectPlant,
                  icon: const Icon(Icons.search),
                  label: const Text(
                    'Detect',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              if (_analyzing) ...[
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.green,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Analysing leaf...',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Processing image and running AI model.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasResult) ...[
                const SizedBox(height: 25),
                _buildResultCard(),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _resetScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Another Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modelLoaded ? Icons.check_circle : Icons.hourglass_top,
                    size: 16,
                    color: _modelLoaded ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _modelLoaded ? 'AI model ready' : 'Loading AI model...',
                    style: TextStyle(
                      color: _modelLoaded ? Colors.green : Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ],
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