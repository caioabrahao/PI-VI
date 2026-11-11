import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_vi/models/estado_lampada.dart';

void main() {
  test('lê o STATUS publicado pela lâmpada', () {
    final estado = EstadoLampada.doJson({
      'ligado': true,
      'brilho': 75,
      'rgb': [255, 120, 0],
    });

    expect(estado, isNotNull);
    expect(estado!.ligado, isTrue);
    expect(estado.brilho, 75);
    expect(EstadoLampada.rgbDe(estado.cor), [255, 120, 0]);
  });

  test('ignora STATUS com formato inválido', () {
    expect(EstadoLampada.doJson({'ligado': 'sim'}), isNull);
    expect(
      EstadoLampada.doJson({
        'ligado': true,
        'brilho': 50,
        'rgb': [1, 2],
      }),
      isNull,
    );
  });

  test('monta comando parcial só com os campos informados', () {
    expect(EstadoLampada.comando(ligado: false), {'ligado': false});
    expect(EstadoLampada.comando(brilho: 5, cor: const Color(0xFF00FF00)), {
      'brilho': EstadoLampada.brilhoMinimo,
      'rgb': [0, 255, 0],
    });
  });
}
