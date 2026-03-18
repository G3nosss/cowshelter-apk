// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/sensor_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color  accentColor;
  final bool   isAlert;

  const SensorCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.unit        = '',
    this.accentColor = const Color(0xFF2E7D32),
    this.isAlert     = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isAlert ? Colors.red : accentColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveColor.withOpacity(0.3),
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color:      effectiveColor.withOpacity(0.10),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment:  MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('ALERT',
                      style: TextStyle(
                          color:       Colors.white,
                          fontSize:    9,
                          fontWeight:  FontWeight.bold,
                          letterSpacing: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.black54,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color:      effectiveColor,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          fontSize: 12,
                          color:    effectiveColor.withOpacity(0.7)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
