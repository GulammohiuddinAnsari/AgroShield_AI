import 'dart:async';
import 'package:flutter/material.dart';
import 'sensor_api_service.dart';
import 'localization_helper.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  final _urlController = TextEditingController(text: 'https://opop-bef0e-default-rtdb.firebaseio.com/Plant_Sensor.json');
  final _service = SensorApiService();
  Timer? _timer;
  SensorReading? _reading;
  String? _error;
  bool _loading = false;
  bool _autoRefresh = true;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchSensors();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_autoRefresh && mounted) _fetchSensors(showLoader: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _urlController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchSensors({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final reading = await _service.fetchReading(_urlController.text);
      if (!mounted) return;
      setState(() {
        _reading = reading;
        _error = null;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Waiting for sensor data';
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    final month = DateTime.now().month;
    final outlook = _outlookForMonth(month);
    final localization = LocalizationHelper.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F3),
      appBar: AppBar(
        title: Text(localization.translate('climate_title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: localization.translate('refresh_sensors'),
            onPressed: _loading ? null : () => _fetchSensors(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B4D3E),
        onRefresh: () => _fetchSensors(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _liveHeader(reading, localization),
            const SizedBox(height: 16),
            _apiSettings(localization),
            const SizedBox(height: 16),
            _sensorGrid(reading, localization),
            const SizedBox(height: 12),
            _recordInfo(reading),
            const SizedBox(height: 16),
            _connectionCard(localization),
            const SizedBox(height: 16),
            _seasonCard(outlook),
            const SizedBox(height: 16),
            _section(
              localization.translate('recommended_farm_actions'),
              [
                'Use the live soil-moisture raw value together with your sensor calibration to decide when irrigation is needed.',
                'Use live temperature and humidity to monitor heat and fungal-risk conditions.',
                'The LDR raw value can be used to identify changing light conditions; it is displayed as a raw ADC value, not a percentage.',
                'The phone only needs internet access because the sensor data is coming from Firebase.',
              ],
              Icons.agriculture_rounded,
              Colors.green.shade700,
            ),
            const SizedBox(height: 16),
            _section(
              localization.translate('business_opportunity'),
              [
                'Live Firebase sensor data can power premium farm monitoring and historical reports.',
                'The marketplace can surface irrigation, spraying and equipment services based on farm conditions.',
                'Premium plans can include sensor history, alerts and advanced climate analytics.',
              ],
              Icons.trending_up_rounded,
              Colors.blue.shade700,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _liveHeader(SensorReading? reading, LocalizationHelper localization) {
    final bool isOnline = reading != null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF2C6B56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      localization.translate('live_farm_sensors'),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.shade400 : Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOnline ? 'LIVE' : 'OFFLINE',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isOnline 
                      ? '${localization.translate('firebase_live')} • Updated ${_formatTime(_lastUpdated)}' 
                      : localization.translate('waiting_firebase'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiSettings(LocalizationHelper localization) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_input_antenna_rounded, color: Color(0xFF1B4D3E), size: 20),
                const SizedBox(width: 8),
                Text(
                  localization.translate('firebase_live_sensor_data'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B4D3E)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              localization.translate('firebase_desc'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: localization.translate('firebase_endpoint'),
                labelStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF1B4D3E)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1B4D3E)),
                  onPressed: () => _fetchSensors(),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(localization.translate('auto_refresh_3s'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _autoRefresh,
              activeColor: const Color(0xFF1B4D3E),
              onChanged: (value) => setState(() => _autoRefresh = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorGrid(SensorReading? reading, LocalizationHelper localization) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard(localization.translate('soil_moisture_raw'), reading == null ? '--' : '${reading.soilMoistureRaw}', Icons.water_drop_rounded, Colors.brown, 'Raw sensor value')),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(localization.translate('ldr_raw'), reading == null ? '--' : '${reading.ldrRaw}', Icons.wb_sunny_rounded, Colors.amber.shade800, 'Raw sensor value')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard(localization.translate('temperature_c'), reading == null ? '--' : '${reading.temperatureC.toStringAsFixed(1)} °C', Icons.thermostat_rounded, Colors.deepOrange, 'Live temperature')),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(localization.translate('temperature_f'), reading == null ? '--' : '${reading.temperatureF.toStringAsFixed(1)} °F', Icons.device_thermostat_rounded, Colors.red.shade700, 'Converted from °C')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard(localization.translate('humidity'), reading == null ? '--' : '${reading.humidity.toStringAsFixed(1)} %', Icons.air_rounded, Colors.teal, 'Relative humidity')),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(localization.translate('data_status'), reading == null ? localization.translate('offline_status') : localization.translate('live_status'), reading == null ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, reading == null ? Colors.red : Colors.green, reading == null ? localization.translate('no_api_resp') : localization.translate('sensor_connected'))),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B4D3E))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _recordInfo(SensorReading? reading) {
    if (reading == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_sync_rounded, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${reading.place ?? 'Plant Sensor'}${reading.deviceId == null ? '' : ' • Device ${reading.deviceId}'}${reading.timestamp == null ? '' : ' • Time ${_formatTime(reading.timestamp)}'}',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionCard(LocalizationHelper localization) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _error == null && _reading != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: _error == null && _reading != null ? Colors.green.shade700 : Colors.orange.shade700,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error == null && _reading != null
                    ? localization.translate('firebase_connected_msg')
                    : (_error ?? localization.translate('waiting_firebase')),
                style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seasonCard(_SeasonOutlook outlook) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_twilight_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  outlook.season,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              outlook.summary,
              style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B4D3E)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(height: 1.4, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  _SeasonOutlook _outlookForMonth(int month) {
    if (month >= 6 && month <= 9) return const _SeasonOutlook('Monsoon Outlook', 'Wet conditions can support crop growth but may increase waterlogging and fungal-disease risk.');
    if (month >= 10 && month <= 11) return const _SeasonOutlook('Post-Monsoon Outlook', 'Transition conditions: review drainage, soil moisture and crop protection plans.');
    if (month >= 3 && month <= 5) return const _SeasonOutlook('Summer Outlook', 'Higher temperatures can increase irrigation demand and heat stress for sensitive crops.');
    return const _SeasonOutlook('Winter Outlook', 'Cooler conditions can reduce water demand; continue crop monitoring and plan the next season.');
  }
}

class _SeasonOutlook {
  final String season;
  final String summary;
  const _SeasonOutlook(this.season, this.summary);
}