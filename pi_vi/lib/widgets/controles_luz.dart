import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Peças visuais de controle de luz, usadas na aba Automações e na tela
/// de controle da lâmpada SmartLight.

/// Cores rápidas mostradas como bolinhas.
const paletaCoresLuz = [
  // Cores puras: a lâmpada recebe exatamente 255 no canal.
  Color(0xFFFFFFFF), // Branco
  Color(0xFFFF0000), // Vermelho
  Color(0xFF00FF00), // Verde
  Color(0xFF0000FF), // Azul
  Color(0xFFFF5C5C),
  Color(0xFFFF984F),
  Color(0xFFFFD15C),
  Color(0xFF4FE0C0),
  Color(0xFF7EC8FF), // Azul atualizado
  Color(0xFF9C75FF),
  Color(0xFFE66BEB),
];

/// Faixa do slider de temperatura de cor, em Kelvin.
const double temperaturaMinimaK = 2200;
const double temperaturaMaximaK = 6500;

String descreverTemperatura(double kelvin) => kelvin < 3500
    ? 'Aconchegante'
    : kelvin > 5000
    ? 'Fria'
    : 'Neutra';

/// Converte uma temperatura de cor (Kelvin) no RGB de um branco
/// equivalente. A lâmpada só entende RGB, então o app faz a conta.
/// Aproximação de Tanner Helland, boa entre 1000 K e 40000 K.
Color corDaTemperatura(double kelvin) {
  final t = kelvin / 100;
  double r, g, b;
  if (t <= 66) {
    r = 255;
    g = 99.4708025861 * math.log(t) - 161.1195681661;
  } else {
    r = 329.698727446 * math.pow(t - 60, -0.1332047592);
    g = 288.1221695283 * math.pow(t - 60, -0.0755148492);
  }
  if (t >= 66) {
    b = 255;
  } else if (t <= 19) {
    b = 0;
  } else {
    b = 138.5177312231 * math.log(t - 10) - 305.0447927307;
  }
  int canal(double v) => v.clamp(0, 255).round();
  return Color.fromARGB(255, canal(r), canal(g), canal(b));
}

class CenaIluminacao {
  final String nome;
  final IconData icone;
  final Color cor;

  /// De 0 a 1.
  final double brilho;
  final double temperatura;

  const CenaIluminacao({
    required this.nome,
    required this.icone,
    required this.cor,
    required this.brilho,
    required this.temperatura,
  });
}

const cenasIluminacao = [
  CenaIluminacao(
    nome: 'Leitura',
    icone: Icons.menu_book_outlined,
    cor: Color(0xFFFFF1D2),
    brilho: 0.95,
    temperatura: 5000,
  ),
  CenaIluminacao(
    nome: 'Relaxar',
    icone: Icons.auto_awesome_outlined,
    cor: Color(0xFFFFB74D),
    brilho: 0.55,
    temperatura: 2700,
  ),
  CenaIluminacao(
    nome: 'Cinema',
    icone: Icons.movie_creation_outlined,
    cor: Color(0xFF9575CD),
    brilho: 0.24,
    temperatura: 3000,
  ),
  CenaIluminacao(
    nome: 'Foco',
    icone: Icons.center_focus_strong_outlined,
    cor: Color(0xFFEAF7FF),
    brilho: 1,
    temperatura: 6000,
  ),
  CenaIluminacao(
    nome: 'Noturna',
    icone: Icons.nightlight_outlined,
    cor: Color(0xFFFF7043),
    brilho: 0.16,
    temperatura: 2200,
  ),
  CenaIluminacao(
    nome: 'Energizar',
    icone: Icons.wb_sunny_outlined,
    cor: Color(0xFFFFD54F),
    brilho: 0.88,
    temperatura: 4500,
  ),
];

/// Slider com título e valor em cima. Valor sempre de 0 a 1.
/// Passe `onChanged: null` para desabilitar.
class LinhaSlider extends StatelessWidget {
  final CosColors c;
  final String titulo;
  final String textoValor;
  final double valor;
  final Color corAtiva;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  const LinhaSlider({
    super.key,
    required this.c,
    required this.titulo,
    required this.textoValor,
    required this.valor,
    required this.corAtiva,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  color: c.fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              textoValor,
              style: TextStyle(
                color: corAtiva,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: corAtiva,
            inactiveTrackColor: c.panelElevated,
            thumbColor: corAtiva,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: valor.clamp(0, 1),
            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

class BolinhaCor extends StatelessWidget {
  final Color cor;
  final bool selecionada;
  final VoidCallback? onTap;

  const BolinhaCor({
    super.key,
    required this.cor,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Num fundo claro a bolinha branca sumiria, e a borda branca de
    // "selecionada" não aparece sobre ela. Cores claras ganham borda cinza.
    final clara = cor.computeLuminance() > 0.8;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: selecionada
              ? Border.all(
                  color: clara ? Colors.black54 : Colors.white,
                  width: 2,
                )
              : clara
              ? Border.all(color: Colors.black26)
              : null,
          boxShadow: selecionada
              ? [BoxShadow(color: cor.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

class CartaoCena extends StatelessWidget {
  final CosColors c;
  final CenaIluminacao cena;
  final bool selecionada;
  final VoidCallback? onTap;

  const CartaoCena({
    super.key,
    required this.c,
    required this.cena,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Material(
        color: selecionada ? c.mint.withValues(alpha: 0.16) : c.panel,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selecionada ? c.mint : c.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cena.icone,
                  color: selecionada ? c.mint : c.muted,
                  size: 19,
                ),
                const SizedBox(height: 5),
                Text(cena.nome, style: TextStyle(color: c.fg, fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Roda de cores: o usuário passa o dedo e escolhe matiz (ângulo) e
/// saturação (distância do centro). O brilho fica com o slider de brilho.
class RodaDeCores extends StatefulWidget {
  final Color cor;
  final double tamanho;
  final ValueChanged<Color>? onChanged;
  final ValueChanged<Color>? onChangeEnd;

  const RodaDeCores({
    super.key,
    required this.cor,
    required this.onChanged,
    this.onChangeEnd,
    this.tamanho = 220,
  });

  @override
  State<RodaDeCores> createState() => _RodaDeCoresState();
}

class _RodaDeCoresState extends State<RodaDeCores> {
  /// Última cor tocada durante o arraste, para mandar no fim.
  Color? _ultimaCor;

  double get _raio => widget.tamanho / 2;

  Color _corNoPonto(Offset posicao) {
    final deslocamento = posicao - Offset(_raio, _raio);
    final saturacao = math.min(deslocamento.distance / _raio, 1.0);
    final matiz =
        (math.atan2(deslocamento.dy, deslocamento.dx) * 180 / math.pi + 360) %
        360;
    return HSVColor.fromAHSV(1, matiz, saturacao, 1).toColor();
  }

  /// Onde desenhar a marquinha da cor atual.
  Offset _pontoDaCor() {
    final hsv = HSVColor.fromColor(widget.cor);
    final angulo = hsv.hue * math.pi / 180;
    return Offset(
      _raio + math.cos(angulo) * hsv.saturation * _raio,
      _raio + math.sin(angulo) * hsv.saturation * _raio,
    );
  }

  void _mover(Offset posicao) {
    final cor = _corNoPonto(posicao);
    _ultimaCor = cor;
    widget.onChanged?.call(cor);
  }

  void _soltar() {
    final cor = _ultimaCor;
    _ultimaCor = null;
    if (cor != null) widget.onChangeEnd?.call(cor);
  }

  @override
  Widget build(BuildContext context) {
    final habilitada = widget.onChanged != null;
    final ponto = _pontoDaCor();

    return GestureDetector(
      onPanDown: habilitada ? (d) => _mover(d.localPosition) : null,
      onPanUpdate: habilitada ? (d) => _mover(d.localPosition) : null,
      onPanEnd: habilitada ? (_) => _soltar() : null,
      // Toque rápido (sem arrastar) cancela o arraste: conta como escolha
      // final também.
      onPanCancel: habilitada ? _soltar : null,
      child: SizedBox(
        width: widget.tamanho,
        height: widget.tamanho,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('automation-color-wheel'),
                painter: _PintorRodaDeCores(),
              ),
            ),
            Positioned(
              left: ponto.dx - 14,
              top: ponto.dy - 14,
              child: IgnorePointer(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.cor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo "Personalizar cor" da aba Automações.
class DialogoRodaDeCores extends StatefulWidget {
  final Color corInicial;

  const DialogoRodaDeCores({super.key, required this.corInicial});

  @override
  State<DialogoRodaDeCores> createState() => _DialogoRodaDeCoresState();
}

class _DialogoRodaDeCoresState extends State<DialogoRodaDeCores> {
  late Color _cor = widget.corInicial;

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);
    return AlertDialog(
      backgroundColor: c.panel,
      title: const Text('Personalizar cor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RodaDeCores(
            cor: _cor,
            onChanged: (cor) => setState(() => _cor = cor),
          ),
          const SizedBox(height: 12),
          Text(
            '#${_cor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _cor),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }
}

class _PintorRodaDeCores extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final raio = math.min(size.width, size.height) / 2;
    final matizes = const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    ).createShader(rect);
    canvas.drawCircle(rect.center, raio, Paint()..shader = matizes);
    final saturacao = const RadialGradient(
      colors: [Colors.white, Color(0x00FFFFFF)],
      stops: [0, 1],
    ).createShader(rect);
    canvas.drawCircle(rect.center, raio, Paint()..shader = saturacao);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
