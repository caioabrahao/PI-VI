import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dispositivo_iot.dart';
import '../models/estado_lampada.dart';
import '../services/servico_mqtt.dart';
import '../theme.dart';
import '../widgets/controles_luz.dart';

/// Tela de controle de uma lâmpada SmartLight pelo MQTT.
///
/// O que aparece na tela é sempre o último STATUS publicado pela lâmpada.
/// Quando o usuário mexe em algo, o app só envia o comando (CMD) e espera
/// a lâmpada confirmar com um novo STATUS. Por isso, girar o encoder físico
/// também atualiza esta tela.
class ControleLampadaScreen extends StatefulWidget {
  final DispositivoIot dispositivo;

  const ControleLampadaScreen({super.key, required this.dispositivo});

  @override
  State<ControleLampadaScreen> createState() => _ControleLampadaScreenState();
}

class _ControleLampadaScreenState extends State<ControleLampadaScreen> {
  final ServicoMqtt _mqtt = ServicoMqtt.instancia;
  StreamSubscription<String>? _assinatura;

  /// Envia no máximo um comando a cada 150 ms enquanto o dedo arrasta,
  /// para a lâmpada acompanhar ao vivo sem inundar o broker.
  static const Duration _intervaloEnvio = Duration(milliseconds: 150);

  /// Quanto tempo esperamos a lâmpada confirmar antes de voltar a mostrar
  /// o último STATUS recebido.
  static const Duration _esperaConfirmacao = Duration(seconds: 2);

  /// Valores "otimistas": o que o usuário pediu e a lâmpada ainda não
  /// confirmou. Enquanto não são null, a tela mostra eles em vez do STATUS,
  /// e o slider não "pula de volta" enquanto a confirmação viaja pela rede.
  bool? _ligadoPedido;
  double? _brilhoPedido;
  Color? _corPedida;

  /// A lâmpada só entende RGB. A temperatura é só do app: guardamos a
  /// última escolhida para o slider não pular, e enviamos o RGB do branco
  /// equivalente (veja corDaTemperatura).
  double _temperatura = 4000;

  bool _dedoNoBrilho = false;
  bool _dedoNaCor = false;
  DateTime _ultimoEnvio = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _expiraPedidos;

  String get _id => widget.dispositivo.identificador;

  @override
  void initState() {
    super.initState();
    _mqtt.garantirConexao();
    _assinatura = _mqtt.mudancas
        .where((id) => id == _id)
        .listen((_) => _aoReceberEstado());
    _mqtt.status.addListener(_aoMudarStatus);
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _expiraPedidos?.cancel();
    _mqtt.status.removeListener(_aoMudarStatus);
    super.dispose();
  }

  void _aoMudarStatus() {
    if (mounted) setState(() {});
  }

  /// Chegou um STATUS novo: descarta os pedidos que a lâmpada já confirmou.
  void _aoReceberEstado() {
    if (!mounted) return;
    final estado = _mqtt.estadoDe(_id);
    setState(() {
      if (estado == null) return;
      if (_ligadoPedido == estado.ligado) _ligadoPedido = null;
      if (!_dedoNoBrilho && _brilhoPedido?.round() == estado.brilho) {
        _brilhoPedido = null;
      }
      final cor = _corPedida;
      if (!_dedoNaCor && cor != null && _mesmaCor(cor, estado.cor)) {
        _corPedida = null;
      }
    });
  }

  static bool _mesmaCor(Color a, Color b) {
    final ra = EstadoLampada.rgbDe(a);
    final rb = EstadoLampada.rgbDe(b);
    return ra[0] == rb[0] && ra[1] == rb[1] && ra[2] == rb[2];
  }

  /// Se a lâmpada não confirmar a tempo, volta a mostrar o STATUS real.
  void _aguardarConfirmacao() {
    _expiraPedidos?.cancel();
    _expiraPedidos = Timer(_esperaConfirmacao, () {
      if (!mounted) return;
      setState(() {
        _ligadoPedido = null;
        if (!_dedoNoBrilho) _brilhoPedido = null;
        if (!_dedoNaCor) _corPedida = null;
      });
    });
  }

  /// Envia durante o arraste, respeitando o intervalo mínimo.
  void _enviarDuranteArraste({int? brilho, Color? cor}) {
    final agora = DateTime.now();
    if (agora.difference(_ultimoEnvio) < _intervaloEnvio) return;
    _ultimoEnvio = agora;
    _enviar(brilho: brilho, cor: cor);
  }

  void _pedirLigado(bool valor) {
    setState(() => _ligadoPedido = valor);
    _enviar(ligado: valor);
    _aguardarConfirmacao();
  }

  void _pedirCor(Color valor) {
    _dedoNaCor = false;
    setState(() => _corPedida = valor);
    _enviar(cor: valor);
    _aguardarConfirmacao();
  }

  /// Enquanto o dedo arrasta na roda de cores ou no slider de temperatura.
  void _arrastarCor(Color valor) {
    _dedoNaCor = true;
    setState(() => _corPedida = valor);
    _enviarDuranteArraste(cor: valor);
  }

  void _aplicarCena(CenaIluminacao cena) {
    final brilho = _brilhoDaCena(cena);
    setState(() {
      _ligadoPedido = true;
      _brilhoPedido = brilho.toDouble();
      _corPedida = cena.cor;
      _temperatura = cena.temperatura;
    });
    _enviar(ligado: true, brilho: brilho, cor: cena.cor);
    _aguardarConfirmacao();
  }

  static int _brilhoDaCena(CenaIluminacao cena) => (cena.brilho * 100)
      .round()
      .clamp(EstadoLampada.brilhoMinimo, EstadoLampada.brilhoMaximo);

  /// Brilho em % (10 a 100) <-> posição do slider (0 a 1).
  static double _posicaoDoBrilho(double brilho) =>
      (brilho - EstadoLampada.brilhoMinimo) /
      (EstadoLampada.brilhoMaximo - EstadoLampada.brilhoMinimo);

  static int _brilhoDaPosicao(double posicao) =>
      (EstadoLampada.brilhoMinimo +
              posicao *
                  (EstadoLampada.brilhoMaximo - EstadoLampada.brilhoMinimo))
          .round();

  void _enviar({bool? ligado, int? brilho, Color? cor}) {
    try {
      _mqtt.publicarComando(
        _id,
        EstadoLampada.comando(ligado: ligado, brilho: brilho, cor: cor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível enviar o comando: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _textoConexao(bool? online) {
    switch (_mqtt.status.value) {
      case StatusMqtt.semConfiguracao:
        return 'MQTT não configurado (veja mqtt.example.json)';
      case StatusMqtt.conectando:
      case StatusMqtt.desconectado:
        return 'Conectando ao broker...';
      case StatusMqtt.erro:
        return 'Falha ao conectar ao broker. Tentando de novo...';
      case StatusMqtt.conectado:
        if (online == null) return 'Aguardando a lâmpada...';
        return online ? 'Online' : 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);
    final estado = _mqtt.estadoDe(_id);
    final online = _mqtt.conectado ? _mqtt.disponibilidadeDe(_id) : null;
    final podeControlar = _mqtt.conectado && online == true && estado != null;
    final ligado = _ligadoPedido ?? estado?.ligado ?? false;
    final cor = _corPedida ?? estado?.cor ?? c.mint;
    final brilho =
        _brilhoPedido ??
        (estado?.brilho ?? EstadoLampada.brilhoMaximo).toDouble();

    CenaIluminacao? cenaAtiva;
    for (final cena in cenasIluminacao) {
      if (ligado &&
          _brilhoDaCena(cena) == brilho.round() &&
          _mesmaCor(cena.cor, cor)) {
        cenaAtiva = cena;
      }
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(widget.dispositivo.nome),
        backgroundColor: c.bg,
        foregroundColor: c.fg,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _cartaoConexao(c, online),
              const SizedBox(height: 16),
              // Sem conexão com a lâmpada, os controles ficam apagados.
              IgnorePointer(
                ignoring: !podeControlar,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: podeControlar ? 1 : 0.45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _botaoLigar(c, ligado, cor),
                      const SizedBox(height: 12),
                      _painelSliders(c, brilho),
                      const SizedBox(height: 13),
                      _titulo(c, 'Cor'),
                      const SizedBox(height: 10),
                      Center(
                        child: RodaDeCores(
                          cor: cor,
                          onChanged: _arrastarCor,
                          onChangeEnd: _pedirCor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final opcao in paletaCoresLuz)
                            BolinhaCor(
                              cor: opcao,
                              selecionada: _mesmaCor(opcao, cor),
                              onTap: () => _pedirCor(opcao),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _titulo(c, 'Cenas')),
                          Text(
                            cenaAtiva?.nome ?? 'Toque para aplicar',
                            style: TextStyle(color: c.mint, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 78,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cenasIluminacao.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cena = cenasIluminacao[index];
                            return CartaoCena(
                              c: c,
                              cena: cena,
                              selecionada: cenaAtiva == cena,
                              onTap: () => _aplicarCena(cena),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titulo(CosColors c, String texto) => Text(
    texto,
    style: TextStyle(color: c.fg, fontWeight: FontWeight.w800),
  );

  Widget _cartaoConexao(CosColors c, bool? online) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: online == true ? c.mint : c.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _textoConexao(online),
              style: TextStyle(color: c.fg, fontSize: 12),
            ),
          ),
          Text(_id, style: TextStyle(color: c.muted, fontSize: 10)),
        ],
      ),
    );
  }

  /// Botão redondo grande, igual ao da aba Automações. Brilha na cor da
  /// lâmpada quando ela está ligada.
  Widget _botaoLigar(CosColors c, bool ligado, Color cor) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pedirLigado(!ligado),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ligado ? cor.withValues(alpha: 0.08) : c.panel,
                border: Border.all(
                  color: ligado ? cor.withValues(alpha: 0.55) : c.border,
                ),
                boxShadow: ligado
                    ? [
                        BoxShadow(
                          color: cor.withValues(alpha: 0.12),
                          blurRadius: 28,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ligado ? cor : c.panelElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: ligado ? c.bg : c.muted,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ligado ? 'Ligada' : 'Desligada',
                style: TextStyle(
                  color: c.fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: ligado,
                onChanged: _pedirLigado,
                activeThumbColor: c.mint,
                activeTrackColor: c.mint.withValues(alpha: 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _painelSliders(CosColors c, double brilho) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          LinhaSlider(
            c: c,
            titulo: 'Brilho',
            textoValor: '${brilho.round()}%',
            valor: _posicaoDoBrilho(brilho),
            corAtiva: c.mint,
            onChangeStart: (_) => _dedoNoBrilho = true,
            onChanged: (v) {
              final novo = _brilhoDaPosicao(v);
              setState(() => _brilhoPedido = novo.toDouble());
              _enviarDuranteArraste(brilho: novo);
            },
            // Ao soltar, sempre envia o valor final.
            onChangeEnd: (v) {
              _dedoNoBrilho = false;
              _enviar(brilho: _brilhoDaPosicao(v));
              _aguardarConfirmacao();
            },
          ),
          const SizedBox(height: 7),
          LinhaSlider(
            c: c,
            titulo: 'Temperatura',
            textoValor:
                '${_temperatura.round()} K · ${descreverTemperatura(_temperatura)}',
            valor:
                (_temperatura - temperaturaMinimaK) /
                (temperaturaMaximaK - temperaturaMinimaK),
            corAtiva: const Color(0xFFFFC45C),
            onChanged: (v) {
              _temperatura =
                  temperaturaMinimaK +
                  v * (temperaturaMaximaK - temperaturaMinimaK);
              _arrastarCor(corDaTemperatura(_temperatura));
            },
            onChangeEnd: (_) => _pedirCor(corDaTemperatura(_temperatura)),
          ),
        ],
      ),
    );
  }
}
