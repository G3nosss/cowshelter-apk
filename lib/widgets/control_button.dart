// ─────────────────────────────────────────────────────────────────────────────
//  lib/widgets/control_button.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final bool     isActive;
  final String?  activeLabel;
  final Color?   activeColor;
  final Future<void> Function() onTap;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive    = false,
    this.activeLabel,
    this.activeColor,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onTap();
    } finally {
      // Guard against calling setState after widget is disposed
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? (widget.activeColor ?? Colors.red)
        : widget.color;
    final label = (widget.isActive && widget.activeLabel != null)
        ? widget.activeLabel!
        : widget.label;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      color.withOpacity(0.30),
              blurRadius: 8,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            else
              Icon(widget.icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
