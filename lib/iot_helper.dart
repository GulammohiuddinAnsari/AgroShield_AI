import 'package:flutter/material.dart';
import 'iot_service.dart';
import 'database_helper.dart';

Widget buildIoTAlertBanner(BuildContext context, VoidCallback onRefresh) {
  final iot = IoTService.instance;
  
  if (!iot.hasAlerts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'IoT Normal | Moist: ${iot.soilMoisture}% | Temp: ${iot.temperature}°C | Hum: ${iot.humidity}%',
              style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: onRefresh,
            tooltip: 'Refresh Sensors',
          ),
        ],
      ),
    );
  }

  String alertMessage = '';
  if (iot.isMoistureLow) alertMessage += 'Low Soil Moisture (${iot.soilMoisture}%). ';
  if (iot.isTemperatureHigh) alertMessage += 'High Temperature (${iot.temperature}°C).';

  // Dismissible allows user to swipe it to the side ("move side")
  return Dismissible(
    key: UniqueKey(),
    direction: DismissDirection.horizontal,
    onDismissed: (direction) async {
      // Store into SQLite IoT history when swiped away
      await DatabaseHelper.instance.insertIoTAlert(alertMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IoT Alert archived to history'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: Colors.red.shade200,
      child: const Icon(Icons.archive, color: Colors.white),
    ),
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.red.shade200,
      child: const Icon(Icons.archive, color: Colors.white),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                'IoT Environmental Alert! (Swipe to clear)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: onRefresh,
                tooltip: 'Refresh Sensors',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (iot.isMoistureLow)
            Text(
              '⚠️ Low Soil Moisture Detected: ${iot.soilMoisture}% (<30%). Triggering drip irrigation.',
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
            ),
          if (iot.isTemperatureHigh)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '🔥 High Temperature Warning: ${iot.temperature}°C (>35°C). Activating greenhouse fans.',
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
              ),
            ),
        ],
      ),
    ),
  );
}