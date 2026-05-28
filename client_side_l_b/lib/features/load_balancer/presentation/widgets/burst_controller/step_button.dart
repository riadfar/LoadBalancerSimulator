import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _StepButton — 28×28 tap target; visually disabled when onTap is null
// ─────────────────────────────────────────────────────────────────────────────

class StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const StepButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: const Color(0xFF1E1E36),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 14,
              color: enabled ? const Color(0xFFBBBBDD) : kMuted,
            ),
          ),
        ),
      ),
    );
  }
}