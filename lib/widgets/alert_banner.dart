// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/alert_banner.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class AlertBanner extends StatefulWidget {
  final SensorData data;
  const AlertBanner({super.key, required this.data});

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.7, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    if (!d.hasAlert) return const SizedBox.shrink();

    final alerts = <_AlertItem>[
      if (d.flame)          _AlertItem('🔥', 'FIRE DETECTED!',             Colors.red.shade700),
      if (d.isGasDangerous) _AlertItem('💨', 'High Gas Level — MQ-2: ${d.gas}',  Colors.deepOrange),
      if (d.isAirBad)       _AlertItem('🌫️', 'Poor Air Quality — MQ-135: ${d.air}', Colors.orange.shade800),
    ];

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color:        Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: Colors.red.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color:      Colors.red.withOpacity(0.12),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 16),
              const SizedBox(width: 6),
              const Text('ACTIVE ALERTS',
                  style: TextStyle(
                      color:       Colors.red,
                      fontWeight:  FontWeight.bold,
                      fontSize:    12,
                      letterSpacing: 0.8)),
            ]),
            const SizedBox(height: 8),
            ...alerts.map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.message,
                        style: TextStyle(
                            color:      a.color,
                            fontWeight: FontWeight.w600,
                            fontSize:   13)),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem {
  final String emoji;
  final String message;
  final Color  color;
  const _AlertItem(this.emoji, this.message, this.color);
}
