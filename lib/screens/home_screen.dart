// ─────────────────────────────────────────────────────────────────────────────
//  lib/screens/home_screen.dart  (v2 — Gate=Servo, Fan=Exhaust)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/camera_feed.dart';
import '../widgets/control_button.dart';
import '../widgets/sensor_card.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SensorData? _data;
  bool        _loading   = true;
  bool        _connected = false;
  Timer?      _pollTimer;

  final _api    = ApiService();
  final _notify = NotificationService();

  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _notify.onAlert = (title, body) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title — $body'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    };
    _fetchData();
    _pollTimer = Timer.periodic(
      Duration(seconds: AppConfig.refreshSeconds),
      (_) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final result = await _api.fetchSensorData();
    if (!mounted) return;
    setState(() {
      _loading   = false;
      _connected = result != null;
      if (result != null) _data = result;
    });
    if (result != null) await _notify.checkAndNotify(result);
  }

  Future<void> _sendCommand(String url) async {
    await _api.sendCommand(url);
    await _fetchData();
  }

  String _fmt(double? v, {int decimals = 1}) =>
      v == null ? '--' : v.toStringAsFixed(decimals);

  void _goHistory() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const HistoryScreen()));

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: _appBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: _green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_connected) _offlineBanner(),
                    if (d != null && d.hasAlert) AlertBanner(data: d),

                    _label('📷  Live Camera'),
                    const CameraFeed(),
                    const SizedBox(height: 20),

                    _label('📡  Live Sensors'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        SensorCard(
                          emoji: '🌡️', label: 'Temperature',
                          value: _fmt(d?.temp), unit: '°C',
                          accentColor: Colors.orange,
                        ),
                        SensorCard(
                          emoji: '💧', label: 'Humidity',
                          value: _fmt(d?.hum, decimals: 0), unit: '%',
                          accentColor: Colors.blue,
                        ),
                        SensorCard(
                          emoji: '💨', label: 'Gas (MQ-2)',
                          value: d?.gas.toString() ?? '--',
                          accentColor: Colors.deepOrange,
                          isAlert: d?.isGasDangerous ?? false,
                        ),
                        SensorCard(
                          emoji: '🌫️', label: 'Air Quality (MQ-135)',
                          value: d?.air.toString() ?? '--',
                          accentColor: Colors.purple,
                          isAlert: d?.isAirBad ?? false,
                        ),
                        SensorCard(
                          emoji: (d?.flame == true) ? '🔥' : '✅',
                          label: 'Flame Sensor',
                          value: (d?.flame == true) ? 'FIRE!' : 'Safe',
                          accentColor: Colors.green,
                          isAlert: d?.flame ?? false,
                        ),
                        SensorCard(
                          emoji: _connected ? '🟢' : '🔴',
                          label: 'Status',
                          value: _connected ? 'Online' : 'Offline',
                          accentColor: _connected ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _label('🎛️  Controls'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.7,
                      children: [
                        // Gate — MG90S Servo
                        ControlButton(
                          icon: (d?.gateOpen == true)
                              ? Icons.door_front_door
                              : Icons.door_back_door_outlined,
                          label:       'Open Gate',
                          activeLabel: 'Close Gate',
                          color:       _green,
                          activeColor: Colors.red,
                          isActive:    d?.gateOpen ?? false,
                          onTap: () => _sendCommand(
                            (d?.gateOpen == true)
                                ? AppConfig.gateClose
                                : AppConfig.gateOpen,
                          ),
                        ),
                        // Buzzer
                        ControlButton(
                          icon: (d?.buzzerOn == true)
                              ? Icons.volume_off
                              : Icons.volume_up_rounded,
                          label:       'Buzzer ON',
                          activeLabel: 'Buzzer OFF',
                          color:       Colors.amber.shade700,
                          activeColor: Colors.red,
                          isActive:    d?.buzzerOn ?? false,
                          onTap: () => _sendCommand(
                            (d?.buzzerOn == true)
                                ? AppConfig.buzzerOff
                                : AppConfig.buzzerOn,
                          ),
                        ),
                        // Exhaust Fan
                        ControlButton(
                          icon: (d?.fanOn == true)
                              ? Icons.air
                              : Icons.air_outlined,
                          label:       'Fan ON',
                          activeLabel: 'Fan OFF',
                          color:       Colors.indigo,
                          activeColor: Colors.indigo.shade300,
                          isActive:    d?.fanOn ?? false,
                          onTap: () => _sendCommand(
                            (d?.fanOn == true)
                                ? AppConfig.fanOff
                                : AppConfig.fanOn,
                          ),
                        ),
                        // Refresh
                        ControlButton(
                          icon:  Icons.refresh_rounded,
                          label: 'Refresh',
                          color: Colors.teal,
                          onTap: _fetchData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // History
                    GestureDetector(
                      onTap: _goHistory,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.show_chart, color: Colors.white),
                            SizedBox(width: 10),
                            Text('View Sensor History & Graphs',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _appBar() => AppBar(
        backgroundColor: _green,
        elevation: 0,
        title: const Row(children: [
          Text('🐄', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Cow Shelter Monitor',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _connected ? Colors.greenAccent : Colors.red.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'History',
            onPressed: _goHistory,
          ),
        ],
      );

  Widget _offlineBanner() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Row(children: [
          Icon(Icons.wifi_off, color: Colors.grey, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cannot reach Arduino. Connect phone to "CowShelter_Demo" WiFi.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ]),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _green)),
      );
}
