import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'localization_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = DatabaseHelper.instance.getScanHistory();
    });
  }

  Future<void> _deleteItem(int id, LocalizationHelper localization) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(localization.translate('delete_title'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B4D3E))),
        content: Text(localization.translate('delete_content'), style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localization.translate('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(localization.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteScanHistory(id);
      _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('delete_success')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B4D3E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = LocalizationHelper.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        title: Text(
          localization.translate('history_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B4D3E),
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading history: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_edu_rounded, size: 56, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localization.translate('no_history'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = item['id'] as int;
              final imagePath = item['image_path'] as String;
              final diseaseName = (item['disease_name'] as String).replaceAll('___', ' - ');
              final confidence = (item['confidence'] as double) * 100;
              final timestamp = item['timestamp'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Thumbnail Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: File(imagePath).existsSync()
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    '${confidence.toStringAsFixed(1)}% match',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              diseaseName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4D3E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete Action Button
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
                        onPressed: () => _deleteItem(id, localization),
                        tooltip: localization.translate('delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(String rawTimestamp) {
    try {
      final dt = DateTime.parse(rawTimestamp).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawTimestamp;
    }
  }
}