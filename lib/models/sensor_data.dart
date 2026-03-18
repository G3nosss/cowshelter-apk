// ─────────────────────────────────────────────────────────────────────────────
//  lib/models/sensor_data.dart  (v2 — fanOn replaces lightOn)
// ─────────────────────────────────────────────────────────────────────────────

import '../config.dart';

class SensorData {
  final double   temp;
  final double   hum;
  final int      gas;
  final int      air;
  final bool     flame;
  final bool     buzzerOn;
  final bool     gateOpen;
  final bool     fanOn;       // exhaust fan (was lightOn)
  final DateTime timestamp;

  const SensorData({
    required this.temp,
    required this.hum,
    required this.gas,
    required this.air,
    required this.flame,
    required this.buzzerOn,
    required this.gateOpen,
    required this.fanOn,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temp:      (json['temp']   as num?)?.toDouble() ?? 0.0,
      hum:       (json['hum']    as num?)?.toDouble() ?? 0.0,
      gas:       (json['gas']    as num?)?.toInt()    ?? 0,
      air:       (json['air']    as num?)?.toInt()    ?? 0,
      flame:     (json['flame']  as int?) == 1,
      buzzerOn:  (json['buzzer'] as int?) == 1,
      gateOpen:  (json['gate']   as int?) == 1,
      fanOn:     (json['fan']    as int?) == 1,
      timestamp: DateTime.now(),
    );
  }

  String toCsv() =>
      '$temp,$hum,$gas,$air,${flame ? 1 : 0},${timestamp.millisecondsSinceEpoch}';

  static SensorData? fromCsv(String csv) {
    try {
      final p = csv.split(',');
      if (p.length < 6) return null;
      return SensorData(
        temp:      double.parse(p[0]),
        hum:       double.parse(p[1]),
        gas:       int.parse(p[2]),
        air:       int.parse(p[3]),
        flame:     p[4] == '1',
        buzzerOn:  false,
        gateOpen:  false,
        fanOn:     false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(p[5])),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isGasDangerous => gas  > AppConfig.gasThreshold;
  bool get isAirBad       => air  > AppConfig.airThreshold;
  bool get hasAlert       => flame || isGasDangerous || isAirBad;
}
