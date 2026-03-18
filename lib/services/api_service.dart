// ─────────────────────────────────────────────────────────────────────────────
//  lib/services/api_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/sensor_data.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _historyKey = 'sensor_history_v1';
  static const Duration _timeout  = Duration(seconds: 3);

  // ── Fetch sensor data ─────────────────────────────────────────────────────────
  Future<SensorData?> fetchSensorData() async {
    try {
      final res = await http
          .get(Uri.parse(AppConfig.dataUrl))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final data = SensorData.fromJson(decoded);
        await _saveToHistory(data);
        return data;
      }
    } catch (_) {
      // Network error or timeout — return null, UI shows offline state
    }
    return null;
  }

  // ── Generic command sender ────────────────────────────────────────────────────
  Future<bool> sendCommand(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── History ───────────────────────────────────────────────────────────────────
  Future<void> _saveToHistory(SensorData data) async {
    final prefs   = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? [];
    current.add(data.toCsv());
    if (current.length > AppConfig.maxHistoryPoints) {
      current.removeRange(0, current.length - AppConfig.maxHistoryPoints);
    }
    await prefs.setStringList(_historyKey, current);
  }

  Future<List<SensorData>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rows  = prefs.getStringList(_historyKey) ?? [];
    return rows
        .map(SensorData.fromCsv)
        .whereType<SensorData>()
        .toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
