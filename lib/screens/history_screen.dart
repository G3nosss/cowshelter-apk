// ─────────────────────────────────────────────────────────────────────────────
//  lib/screens/history_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  List<SensorData> _history = [];
  bool             _loading = true;
  late TabController _tabs;

  static const _tabConfigs = [
    _TabConfig('🌡️ Temp',     Colors.orange,     'Temperature',        '°C', 0,   60),
    _TabConfig('💧 Humidity', Colors.blue,        'Humidity',           '%',  0,  100),
    _TabConfig('💨 Gas',      Colors.deepOrange,  'Gas Level (MQ-2)',   '',   0,    0),
    _TabConfig('🌫️ Air',      Colors.purple,      'Air Quality (MQ-135)', '', 0,  0),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await ApiService().loadHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _loading = false;
      });
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Clear History?'),
        content: const Text('All saved sensor readings will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ApiService().clearHistory();
      if (mounted) {
        setState(() {
          _history = [];
          _loading = false;
        });
      }
    }
  }

  // ── Build spots for a given field ────────────────────────────────────────────
  List<FlSpot> _spots(double Function(SensorData) fn) {
    return _history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), fn(e.value)))
        .toList();
  }

  // ── Single chart widget ───────────────────────────────────────────────────────
  Widget _buildChart({
    required Color    color,
    required List<FlSpot> spots,
    required String   unit,
    double? minY,
    double? maxY,
  }) {
    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No data yet.',
                style: TextStyle(color: Colors.black38)),
            const SizedBox(height: 4),
            const Text('Keep the app running — data saves automatically.',
                style: TextStyle(color: Colors.black26, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // X-axis label interval
    final interval = spots.length > 10
        ? (spots.length / 5).floorToDouble()
        : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color:       Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),

          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left:   BorderSide(color: Colors.grey.shade300),
            ),
          ),

          titlesData: FlTitlesData(
            topTitles:   const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval:   interval,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _history.length) {
                    return const SizedBox.shrink();
                  }
                  final t = _history[idx].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${t.hour.toString().padLeft(2, '0')}:'
                      '${t.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black38),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 44,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}$unit',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black45),
                ),
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots:           spots,
              isCurved:        true,
              curveSmoothness: 0.35,
              color:           color,
              barWidth:        2.5,
              dotData: FlDotData(
                show: spots.length <= 20,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius:       3,
                  color:        color,
                  strokeWidth:  1.5,
                  strokeColor:  Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.22),
                    color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ],

          // Tooltip on touch
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.black87,
              // fl_chart 0.68 uses tooltipBgColor (not a callback)
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}$unit',
                    TextStyle(
                      color:      color,
                      fontWeight: FontWeight.bold,
                      fontSize:   12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Sensor History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
          IconButton(
            icon:    const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: _confirmClear,
          ),
        ],
        bottom: TabBar(
          controller:          _tabs,
          indicatorColor:      Colors.white,
          labelColor:          Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabConfigs
              .map((c) => Tab(text: c.tabLabel))
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_history.isNotEmpty) _buildSummaryBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _chartCard(0, _spots((d) => d.temp)),
                      _chartCard(1, _spots((d) => d.hum)),
                      _chartCard(2, _spots((d) => d.gas.toDouble())),
                      _chartCard(3, _spots((d) => d.air.toDouble())),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chartCard(int idx, List<FlSpot> spots) {
    final cfg      = _tabConfigs[idx];
    final color    = cfg.color as Color;
    final hasThreshold = idx == 2 || idx == 3;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset:     const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cfg.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   15,
                          color:      color)),
                  Text('${_history.length} readings',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38)),
                ],
              ),
            ),
            if (hasThreshold)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  idx == 2
                      ? '⚠️ Danger above 400'
                      : '⚠️ Poor air above 500',
                  style: TextStyle(
                      fontSize: 11, color: Colors.orange.shade700),
                ),
              ),
            Expanded(
              child: _buildChart(
                color: color,
                spots: spots,
                unit:  cfg.unit,
                minY:  cfg.minY == 0 && cfg.maxY == 0 ? null : cfg.minY,
                maxY:  cfg.minY == 0 && cfg.maxY == 0 ? null : cfg.maxY,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final last = _history.last;
    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Readings', '${_history.length}', Colors.black54),
          _stat('Temp',     '${last.temp.toStringAsFixed(1)}°C', Colors.orange),
          _stat('Hum',      '${last.hum.toStringAsFixed(0)}%',   Colors.blue),
          _stat('Gas',      '${last.gas}',
              last.isGasDangerous ? Colors.red : Colors.green),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Colors.black38)),
    ],
  );
}

// ── Simple config holder ──────────────────────────────────────────────────────
class _TabConfig {
  final String tabLabel;
  final Object color;   // Color constant
  final String title;
  final String unit;
  final double minY;
  final double maxY;

  const _TabConfig(
      this.tabLabel, this.color, this.title, this.unit, this.minY, this.maxY);
}
