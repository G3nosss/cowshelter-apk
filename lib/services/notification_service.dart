// ─────────────────────────────────────────────────────────────────────────────
//  lib/services/notification_service.dart
//  Web-safe: no flutter_local_notifications dependency.
//  Uses in-app alert tracking only — UI layer shows banners via alert_banner.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../models/sensor_data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _prevFlame  = false;
  bool _prevGas    = false;
  bool _prevAirBad = false;

  // Callbacks — HomeScreen wires these up to show snackbars
  void Function(String title, String body)? onAlert;

  Future<void> init() async {
    // No-op on web. On mobile builds, swap in flutter_local_notifications here.
  }

  Future<void> checkAndNotify(SensorData data) async {
    if (data.flame && !_prevFlame) {
      _notify('FIRE DETECTED!',
          'Flame sensor triggered inside the shelter. Check immediately!');
    }
    _prevFlame = data.flame;

    if (data.isGasDangerous && !_prevGas) {
      _notify('High Gas Level!',
          'MQ-2 reading: ${data.gas}. Possible smoke or gas leak detected.');
    }
    _prevGas = data.isGasDangerous;

    if (data.isAirBad && !_prevAirBad) {
      _notify('Poor Air Quality',
          'MQ-135 reading: ${data.air}. Shelter needs ventilation.');
    }
    _prevAirBad = data.isAirBad;
  }

  void _notify(String title, String body) {
    onAlert?.call(title, body);
  }
}
