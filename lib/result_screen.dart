import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';
import 'localization_helper.dart';

class ResultScreen extends StatefulWidget {
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
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? _remedyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveAndFetchRemedyDetails();
  }

  Future<void> _saveAndFetchRemedyDetails() async {
    await DatabaseHelper.instance.insertScanHistory(
      widget.image.path,
      widget.diseaseName,
      widget.confidence,
    );

    final data = await DatabaseHelper.instance.getRemedyForDisease(widget.diseaseName);
    setState(() {
      _remedyData = data;
      _isLoading = false;
    });
  }

  void _shareReport() {
    if (_remedyData == null) return;

    final plant = _remedyData?['plant_name'] ?? 'Plant';
    final severity = _remedyData?['severity'] ?? 'Normal';
    final treatment = _remedyData?['treatment'] ?? 'N/A';
    final prevention = _remedyData?['prevention'] ?? 'N/A';
    final iotAction = _remedyData?['iot_action'] ?? 'N/A';
    final match = (widget.confidence * 100).toStringAsFixed(1);

    final reportText = '''
🌱 *AgroShield AI - Crop Diagnosis Report* 🌱
----------------------------------------
*Detected Condition:* ${widget.diseaseName.replaceAll('___', ' - ')}
*Crop Type:* $plant
*Severity Level:* $severity
*AI Confidence:* $match%

💊 *Treatment Plan:*
$treatment

🛡️ *Prevention Guidelines:*
$prevention

🤖 *Recommended IoT Action:*
$iotAction
----------------------------------------
Generated offline via AgroShield AI Scanner.
''';

    Share.share(reportText, subject: 'Crop Diagnosis Report: ${widget.diseaseName}');
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationHelper.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: Text(localization.translate('analysis_title')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _isLoading ? null : _shareReport,
            tooltip: 'Share Diagnosis Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.image, 
                      height: 240, 
                      width: double.infinity, 
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localization.translate('detected_condition'),
                              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${(widget.confidence * 100).toStringAsFixed(1)}% ${localization.translate('confidence_match')}",
                                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.diseaseName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${localization.translate('crop_type')}: ${_remedyData?['plant_name'] ?? 'Plant'} | ${localization.translate('severity')}: ${_remedyData?['severity'] ?? 'Normal'}",
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              localization.translate('treatment_remedy'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _remedyData?['treatment'] ?? localization.translate('no_treatment'),
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              localization.translate('prevention_guidelines'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _remedyData?['prevention'] ?? localization.translate('no_prevention'),
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            const Icon(Icons.settings_input_antenna, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              localization.translate('iot_action'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _remedyData?['iot_action'] ?? localization.translate('standard_monitoring'),
                          style: const TextStyle(fontSize: 15, height: 1.4, fontStyle: FontStyle.italic, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}