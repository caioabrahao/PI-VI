import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dispositivo_iot.dart';
import '../models/estado_lampada.dart';
import '../services/servico_mqtt.dart';
import '../theme.dart';

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
  static const List<Color> _coresRapidas = [
    Color(0xFFFFFFFF),
    Color(0xFFFFB74D),
    Color(0xFFFF0000),
    Color(0xFFFF00FF),
    Color(0xFF0000FF),
    Color(0xFF00FFFF),
    Color(0xFF00FF00),
    Color(0xFFFFFF00),
  ];

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
    setState(() => _corPedida = valor);
    _enviar(cor: valor);
    _aguardarConfirmacao();
  }

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
    final matiz = HSVColor.fromColor(cor).hue;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(widget.dispositivo.nome),
        backgroundColor: c.bg,
        foregroundColor: c.fg,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _cartao(
                c,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: online == true ? c.mint : c.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _textoConexao(online),
                        style: TextStyle(color: c.fg),
                      ),
                    ),
                    Text(_id, style: TextStyle(color: c.muted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _cartao(
                c,
                child: Column(
                  children: [
                    Icon(
                      ligado ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 96,
                      color: ligado ? cor : c.muted,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      title: Text(
                        ligado ? 'Ligada' : 'Desligada',
                        style: TextStyle(
                          color: c.fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: ligado,
                      activeThumbColor: c.mint,
                      onChanged: podeControlar ? _pedirLigado : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _cartao(
                c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brilho: ${brilho.round()}%',
                      style: TextStyle(color: c.fg),
                    ),
                    Slider(
                      value: brilho,
                      min: EstadoLampada.brilhoMinimo.toDouble(),
                      max: EstadoLampada.brilhoMaximo.toDouble(),
                      divisions:
                          EstadoLampada.brilhoMaximo -
                          EstadoLampada.brilhoMinimo,
                      onChangeStart: (_) => _dedoNoBrilho = true,
                      onChanged: podeControlar
                          ? (v) {
                              setState(() => _brilhoPedido = v);
                              _enviarDuranteArraste(brilho: v.round());
                            }
                          : null,
                      // Ao soltar, sempre envia o valor final.
                      onChangeEnd: podeControlar
                          ? (v) {
                              _dedoNoBrilho = false;
                              _enviar(brilho: v.round());
                              _aguardarConfirmacao();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _cartao(
                c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cor', style: TextStyle(color: c.fg)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final opcao in _coresRapidas)
                          _bolinhaCor(
                            c,
                            opcao,
                            selecionada: _mesmaCor(opcao, cor),
                            habilitada: podeControlar,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: matiz,
                      max: 360,
                      activeColor: HSVColor.fromAHSV(1, matiz, 1, 1).toColor(),
                      onChangeStart: (_) => _dedoNaCor = true,
                      onChanged: podeControlar
                          ? (v) {
                              final novaCor = HSVColor.fromAHSV(
                                1,
                                v,
                                1,
                                1,
                              ).toColor();
                              setState(() => _corPedida = novaCor);
                              _enviarDuranteArraste(cor: novaCor);
                            }
                          : null,
                      onChangeEnd: podeControlar
                          ? (v) {
                              _dedoNaCor = false;
                              _pedirCor(
                                HSVColor.fromAHSV(1, v, 1, 1).toColor(),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartao(CosColors c, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }

  Widget _bolinhaCor(
    CosColors c,
    Color cor, {
    required bool selecionada,
    required bool habilitada,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: habilitada ? () => _pedirCor(cor) : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cor,
          shape: BoxShape.circle,
          border: Border.all(
            color: selecionada ? c.mint : c.border,
            width: selecionada ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
