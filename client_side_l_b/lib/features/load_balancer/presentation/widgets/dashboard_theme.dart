import 'package:flutter/material.dart';

// ── Colour palette ────────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF6826BD);
const kBackground   = Color(0xFF0D0D1A);
const kSurface      = Color(0xFF15152A);
const kBorder       = Color(0xFF242438);
const kTerminalBg   = Color(0xFF07070F);
const kSuccessGreen = Color(0xFF39FF14);
const kErrorRed     = Color(0xFFFF4455);
const kCyan         = Color(0xFF00CFFF);
const kMuted        = Color(0xFF5A5A7A);

// ── Active-load colour thresholds (green → gold → orange → red) ───────────────
Color loadColor(int load) {
  if (load <= 2)  return const Color(0xFF39FF14); // neon green  — calm
  if (load <= 6)  return const Color(0xFFFFD700); // gold        — warming up
  if (load <= 12) return const Color(0xFFFF9500); // orange      — busy
  return          const Color(0xFFFF4455);         // red         — under pressure
}
