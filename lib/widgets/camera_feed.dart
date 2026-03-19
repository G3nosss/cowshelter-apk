// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/camera_feed.dart
//  Polls /capture endpoint every 100ms for smooth live feed
//  Works reliably on Android without any extra packages
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class CameraFeed extends StatefulWidget {
  const CameraFeed({super.key});

  @override
  State<CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  Timer?      _timer;
  Uint8List?  _imageBytes;
  bool        _hasError  = false;
  bool        _loading   = true;
  int         _tick      = 0;

  // Poll interval — increase if still laggy (100=10fps, 150=7fps, 200=5fps)
  static const int _intervalMs = 100;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _fetchFrame(); // immediate first frame
    _timer = Timer.periodic(
      const Duration(milliseconds: _intervalMs),
      (_) => _fetchFrame(),
    );
  }

  Future<void> _fetchFrame() async {
    try {
      final url = '${AppConfig.camStream}capture?t=${_tick++}';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _imageBytes = res.bodyBytes;
          _hasError   = false;
          _loading    = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading  = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _loading  = true;
      _hasError = false;
    });
    _timer?.cancel();
    _startPolling();
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

            // ── Camera image ───────────────────────────────────────────────
            ColoredBox(
              color: Colors.black,
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white54),
                          SizedBox(height: 10),
                          Text('Connecting to camera...',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    )
                  : _hasError || _imageBytes == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off,
                                  color: Colors.white24, size: 40),
                              const SizedBox(height: 8),
                              const Text('Camera offline',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('Check ESP32-CAM & WiFi',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 11)),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _retry,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Retry',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.memory(
                          _imageBytes!,
                          fit:             BoxFit.cover,
                          gaplessPlayback: true, // no flicker between frames
                        ),
            ),

            // ── LIVE badge ─────────────────────────────────────────────────
            if (!_hasError && !_loading)
              Positioned(
                top: 10, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 7),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                              color:       Colors.white,
                              fontSize:    10,
                              fontWeight:  FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),

            // ── Label ──────────────────────────────────────────────────────
            Positioned(
              bottom: 10, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ESP32-CAM',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 10)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
