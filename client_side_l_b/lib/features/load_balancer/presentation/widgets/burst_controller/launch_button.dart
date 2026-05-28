import 'package:flutter/material.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _LaunchButton — gradient glow, scale-on-press, fades when total = 0
// ─────────────────────────────────────────────────────────────────────────────

class LaunchButton extends StatefulWidget {
  final int total;
  final VoidCallback? onLaunch;

  const LaunchButton({super.key, required this.total, required this.onLaunch});

  @override
  State<LaunchButton> createState() => LaunchButtonState();
}

class LaunchButtonState extends State<LaunchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onLaunch != null;

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6826BD),
                Color(0xFF9B27FF),
                Color(0xFFB827E0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
              BoxShadow(
                color: const Color(0xFF9B27FF).withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF6826BD).withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.06),
              onHighlightChanged:
              enabled ? (v) => setState(() => _pressed = v) : null,
              onTap: widget.onLaunch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'LAUNCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    if (widget.total > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '×${widget.total}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
