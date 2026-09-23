import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorReading {
  final int soilMoistureRaw;
  final int ldrRaw;
  final double temperatureC;
  final double humidity;
  final DateTime? timestamp;
  final String? deviceId;
  final String? place;

  const SensorReading({
    required this.soilMoistureRaw,
    required this.ldrRaw,
    required this.temperatureC,
    required this.humidity,
    this.timestamp,
    this.deviceId,
    this.place,
  });

  double get temperatureF => (temperatureC * 9 / 5) + 32;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    num? number(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value;
        if (value is String) {
          final parsed = num.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final soil = number([
      'soilMoistureRaw',
      'soil_moisture_raw',
      'soilMoisture',
      'soil_raw',
      'moisture',
    ]);
    final ldr = number([
      'ldrRaw',
      'ldr_raw',
      'ldr',
      'lightRaw',
      'light_raw',
    ]);
    final tempC = number([
      'temperatureC',
      'temperature_c',
      'tempC',
      'temp_c',
      'temperature',
    ]);
    final humidity = number([
      'humidity',
      'humidityPercent',
      'humidity_percentage',
    ]);

    if (soil == null || ldr == null || tempC == null || humidity == null) {
      throw const FormatException(
        'Firebase sensor data must contain moisture, ldr, temp_c and humidity.',
      );
    }

    DateTime? time;
    final dateIst = json['date_ist']?.toString();
    final timeIst = json['time_ist']?.toString();
    final dateUtc = json['date_utc']?.toString();
    final timeUtc = json['time_utc']?.toString();
    final rawTimestamp = json['timestamp'] ?? json['time'];

    if (dateIst != null && timeIst != null) {
      time = DateTime.tryParse('$dateIst $timeIst');
    }
    time ??= (dateUtc != null && timeUtc != null)
        ? DateTime.tryParse('${dateUtc}T${timeUtc}Z')?.toLocal()
        : null;
    if (time == null && rawTimestamp is String) {
      time = DateTime.tryParse(rawTimestamp);
    }
    if (time == null && rawTimestamp is num) {
      time = DateTime.fromMillisecondsSinceEpoch(
        rawTimestamp.toInt(),
        isUtc: true,
      ).toLocal();
    }

    return SensorReading(
      soilMoistureRaw: soil.round(),
      ldrRaw: ldr.round(),
      temperatureC: tempC.toDouble(),
      humidity: humidity.toDouble(),
      timestamp: time,
      deviceId: json['device_id']?.toString(),
      place: json['place']?.toString(),
    );
  }
}

class SensorApiService {
  final http.Client _client;
  SensorApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<SensorReading> fetchReading(String endpoint) async {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a valid Firebase/API URL.');
    }

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Sensor API returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Firebase response must be a JSON object.');
    }

    // Firebase Realtime Database returns Plant_Sensor as an object whose
    // children are sensor records, e.g. {"1790143296_1": {...}}.
    // Select the newest record using date/time, then fall back to the last key.
    final records = <Map<String, dynamic>>[];
    for (final value in decoded.values) {
      if (value is Map) {
        records.add(Map<String, dynamic>.from(value));
      }
    }

    if (records.isNotEmpty) {
      records.sort((a, b) {
        final ta = _recordDateTime(a);
        final tb = _recordDateTime(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return ta.compareTo(tb);
      });
      return SensorReading.fromJson(records.last);
    }

    // Also support a single sensor object directly at the endpoint.
    return SensorReading.fromJson(Map<String, dynamic>.from(decoded));
  }

  DateTime? _recordDateTime(Map<String, dynamic> json) {
    final date = json['date_ist']?.toString();
    final time = json['time_ist']?.toString();
    if (date != null && time != null) {
      return DateTime.tryParse('$date $time');
    }

    final raw = json['timestamp'] ?? json['time'];
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
    }
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  void dispose() => _client.close();
}
