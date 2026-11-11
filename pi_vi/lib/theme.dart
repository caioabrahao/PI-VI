import 'package:flutter/material.dart';

/// Notifier global do tema. Uma única instância para o app inteiro.
final ValueNotifier<ThemeMode> perfilThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

/// Paleta do COS resolvida para o brilho atual.
class CosColors {
  final Color bg;
  final Color panel;
  final Color panel2;
  final Color panelElevated;
  final Color border;
  final Color muted;
  final Color fg;
  final Color mint;

  const CosColors({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.panelElevated,
    required this.border,
    required this.muted,
    required this.fg,
    required this.mint,
  });

  /// Paleta escura (pública — usada em `automacao.dart`).
  static const CosColors dark = CosColors(
    bg: Color(0xFF080B0F),
    panel: Color(0xFF10151B),
    panel2: Color(0xFF171E26),
    panelElevated: Color(0xFF1E2830),
    border: Color(0xFF293640),
    muted: Color(0xFF8A98A5),
    fg: Color(0xFFF1F5F8),
    mint: Color(0xFF4FE0C0),
  );

  /// Paleta clara.
  static const CosColors light = CosColors(
    bg: Color(0xFFF3F7F6),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFEAF1EF),
    panelElevated: Color(0xFFDDE9E6),
    border: Color(0xFFD6E2DF),
    muted: Color(0xFF566970),
    fg: Color(0xFF172C30),
    mint: Color(0xFF00836F),
  );

  static CosColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

extension CosColorsX on BuildContext {
  CosColors get cos => CosColors.of(this);
}
