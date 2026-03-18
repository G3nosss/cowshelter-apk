// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/camera_feed.dart
//  MJPEG-style feed from ESP32-CAM — no external package needed.
//  Periodically refreshes a JPEG snapshot from http://192.168.4.2/capture
//  Works on web, Android, and iOS.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../config.dart';

class CameraFeed extends StatefulWidget {
  const CameraFeed({super.key});
  @override
  State<CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  Timer?  _timer;
  int     _tick     = 0;
  bool    _hasError = false;

  // ESP32-CAM: stream endpoint (MJPEG) or /capture for snapshot
  // We use snapshot with cache-busting for universal compatibility
  String get _frameUrl =>
      '${AppConfig.camStream}capture?t=$_tick';

  @override
  void initState() {
    super.initState();
    _startRefresh();
  }

  void _startRefresh() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() { _tick++; _hasError = false; });
    });
  }

  void _retry() {
    setState(() { _tick++; _hasError = false; });
    _timer?.cancel();
    _startRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: _hasError
                  ? _offlineWidget()
                  : Image.network(
                      _frameUrl,
                      key: ValueKey(_tick),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return _tick == 0
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white54),
                                    SizedBox(height: 10),
                                    Text('Connecting to camera...',
                                        style: TextStyle(
                                            color: Colors.white54, fontSize: 12)),
                                    SizedBox(height: 4),
                                    Text('Make sure ESP32-CAM is powered on',
                                        style: TextStyle(
                                            color: Colors.white30, fontSize: 10)),
                                  ],
                                ),
                              )
                            : child;
                      },
                      errorBuilder: (ctx, err, stack) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _hasError = true);
                        });
                        return _offlineWidget();
                      },
                    ),
            ),
            // LIVE badge
            if (!_hasError)
              Positioned(
                top: 10, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 7),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            // CAM label
            Positioned(
              bottom: 10, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('ESP32-CAM',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offlineWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
            const SizedBox(height: 8),
            const Text('Camera offline',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Check ESP32-CAM & WiFi connection',
                style: TextStyle(color: Colors.white24, fontSize: 11)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _retry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
}
