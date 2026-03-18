// ─────────────────────────────────────────────────────────────────────────────
//  lib/config.dart
//  Fixed IPs — Uno R4 is the WiFi hotspot
//  R4  always = 192.168.4.1
//  CAM always = 192.168.4.2 (static IP in ESP32-CAM firmware)
//
//  Connect phone to "CowShelter_Demo" WiFi before opening app.
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  static const String r4IP  = "192.168.4.1";
  static const String camIP = "192.168.4.2";

  static String get dataUrl   => "http://$r4IP/data";
  static String get buzzerOn  => "http://$r4IP/buzzer/on";
  static String get buzzerOff => "http://$r4IP/buzzer/off";
  static String get gateOpen  => "http://$r4IP/gate/open";
  static String get gateClose => "http://$r4IP/gate/close";
  static String get fanOn     => "http://$r4IP/fan/on";
  static String get fanOff    => "http://$r4IP/fan/off";
  static String get camStream => "http://$camIP/";

  static const int gasThreshold    = 400;
  static const int airThreshold    = 500;
  static const int maxHistoryPoints = 50;
  static const int refreshSeconds   = 3;
  static const String wifiSSID = "CowShelter_Demo";
  static const String wifiPass = "shelter2024";
}
