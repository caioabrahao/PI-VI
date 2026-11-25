import 'dart:ui' show Color;

/// Estado de uma lâmpada SmartLight, no mesmo formato JSON do firmware
/// (classe InterpretadoraDeEstado do ESP32):
///
/// ```json
/// {"ligado": true, "brilho": 75, "rgb": [255, 120, 0]}
/// ```
///
/// - `brilho` vai de 10 a 100 (%), como no firmware.
/// - `rgb` tem 3 valores de 0 a 255.
class EstadoLampada {
  static const int brilhoMinimo = 10;
  static const int brilhoMaximo = 100;

  final bool ligado;
  final int brilho;
  final Color cor;

  const EstadoLampada({
    required this.ligado,
    required this.brilho,
    required this.cor,
  });

  /// Lê o JSON publicado pela lâmpada em `smartlight/<id>/STATUS`.
  /// Retorna `null` se o JSON não tiver o formato esperado.
  static EstadoLampada? doJson(Map<String, dynamic> json) {
    final ligado = json['ligado'];
    final brilho = json['brilho'];
    final rgb = json['rgb'];

    if (ligado is! bool || brilho is! num || rgb is! List || rgb.length != 3) {
      return null;
    }

    int canal(Object? valor) => valor is num ? valor.toInt().clamp(0, 255) : 0;

    return EstadoLampada(
      ligado: ligado,
      brilho: brilho.toInt().clamp(brilhoMinimo, brilhoMaximo),
      cor: Color.fromARGB(255, canal(rgb[0]), canal(rgb[1]), canal(rgb[2])),
    );
  }

  /// Monta um comando parcial para `smartlight/<id>/CMD`.
  /// Só os campos informados são enviados; a lâmpada mantém o resto.
  static Map<String, dynamic> comando({bool? ligado, int? brilho, Color? cor}) {
    return {
      'ligado': ?ligado, // o '?' só inclui a chave se não for null
      if (brilho != null) 'brilho': brilho.clamp(brilhoMinimo, brilhoMaximo),
      if (cor != null) 'rgb': rgbDe(cor),
    };
  }

  static List<int> rgbDe(Color cor) => [
    (cor.r * 255).round(),
    (cor.g * 255).round(),
    (cor.b * 255).round(),
  ];
}
