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
    final severity = _remedyData?['severity'] ?? 'Moderate';
    final treatment = _remedyData?['treatment'] ?? 'N/A';
    final prevention = _remedyData?['prevention'] ?? 'N/A';
    final match = (widget.confidence * 100).toStringAsFixed(1);
    final formattedName = widget.diseaseName.replaceAll('___', ' - ');

    final reportText = '''
🌱 AgroShield AI - Diagnostic Analysis Report 🌱
----------------------------------------
• Detected Condition: $formattedName
• Target Crop: $plant
• Severity Index: $severity
• Neural Confidence: $match%

💊 Agronomic Treatment Protocol:
$treatment

🛡️ Biosecurity & Prevention Guidelines:
$prevention
----------------------------------------
Processed locally via AgroShield AI Edge Engine.
''';

    Share.share(reportText, subject: 'Crop Diagnostic Report: $formattedName');
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationHelper.instance;
    final formattedDiseaseName = widget.diseaseName.replaceAll('___', ' - ');
    final confidencePercent = (widget.confidence * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        title: Text(
          localization.translate('analysis_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _isLoading ? null : _shareReport,
            tooltip: 'Share Diagnosis Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B4D3E),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scanned Image Preview Card
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B4D3E).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        widget.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Diagnosis Summary Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
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
                              localization.translate('detected_condition').toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$confidencePercent% ${localization.translate('confidence_match')}",
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formattedDiseaseName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B4D3E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _metaBadge(Icons.eco_rounded, "${localization.translate('crop_type')}: ${_remedyData?['plant_name'] ?? 'Plant'}"),
                            const SizedBox(width: 12),
                            _metaBadge(Icons.warning_amber_rounded, "${localization.translate('severity')}: ${_remedyData?['severity'] ?? 'Moderate'}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Treatment Protocol Card
                  _buildContentCard(
                    title: localization.translate('treatment_remedy'),
                    icon: Icons.medical_services_rounded,
                    iconColor: Colors.green.shade700,
                    content: _remedyData?['treatment'] ?? localization.translate('no_treatment'),
                  ),
                  const SizedBox(height: 16),

                  // Prevention Guidelines Card
                  _buildContentCard(
                    title: localization.translate('prevention_guidelines'),
                    icon: Icons.shield_rounded,
                    iconColor: Colors.blue.shade700,
                    content: _remedyData?['prevention'] ?? localization.translate('no_prevention'),
                  ),
                  const SizedBox(height: 24),

                  // Developer Attribution / Offline Verification Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Engineered for field reliability • Local SQLite Persistence & TFLite Neural Execution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
    );
  }

  Widget _metaBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}