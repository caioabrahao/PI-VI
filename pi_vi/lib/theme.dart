import 'package:flutter/material.dart';

/// Notifier global do tema. Uma única instância para o app inteiro.
final ValueNotifier<ThemeMode> perfilThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

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

  /// Paleta escura refinada (Deep Forest)
  static const CosColors dark = CosColors(
    bg: Color(0xFF0B1311),             // Fundo verde quase preto
    panel: Color(0xFF131E1A),          // Painéis verde musgo escuro
    panel2: Color(0xFF1A2823),         // Painéis elevados (Inputs)
    panelElevated: Color(0xFF22332E),  // Fundo de ícones e botões secundários
    border: Color(0xFF2E423C),         // Bordas suaves
    muted: Color(0xFF7A9990),          // Texto secundário
    fg: Color(0xFFE6F0EC),             // Texto principal branco gelo
    mint: Color(0xFF2AD492),           // Destaque (Esmeralda equilibrado)
  );

  /// Paleta clara refinada
  static const CosColors light = CosColors(
    bg: Color(0xFFF2F7F5),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFEAF1EF),
    panelElevated: Color(0xFFDDE9E6),
    border: Color(0xFFD6E2DF),
    muted: Color(0xFF566970),
    fg: Color(0xFF13211D),
    mint: Color(0xFF009B6B),           // Destaque verde escuro
  );

  static CosColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

extension CosColorsX on BuildContext {
  CosColors get cos => CosColors.of(this);
}