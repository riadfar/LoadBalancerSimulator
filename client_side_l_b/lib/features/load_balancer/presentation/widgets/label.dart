import 'package:flutter/material.dart';

import 'dashboard_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _Label — section header with accent bar and optional trailing action
// ─────────────────────────────────────────────────────────────────────────────

class Label extends StatelessWidget {
  final String title;
  final Widget? action;

  const Label({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7777AA),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }
}
