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

  /// Valor do slider enquanto o dedo está arrastando (null = usar o STATUS).
  double? _brilhoArrastando;
  double? _matizArrastando;

  String get _id => widget.dispositivo.identificador;

  @override
  void initState() {
    super.initState();
    _mqtt.garantirConexao();
    _assinatura = _mqtt.mudancas
        .where((id) => id == _id)
        .listen((_) => setState(() {}));
    _mqtt.status.addListener(_aoMudarStatus);
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _mqtt.status.removeListener(_aoMudarStatus);
    super.dispose();
  }

  void _aoMudarStatus() {
    if (mounted) setState(() {});
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
    final ligado = estado?.ligado ?? false;
    final cor = estado?.cor ?? c.mint;
    final brilho =
        _brilhoArrastando ??
        (estado?.brilho ?? EstadoLampada.brilhoMaximo).toDouble();
    final matiz = _matizArrastando ?? HSVColor.fromColor(cor).hue;

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
                      onChanged: podeControlar
                          ? (valor) => _enviar(ligado: valor)
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
                      onChanged: podeControlar
                          ? (v) => setState(() => _brilhoArrastando = v)
                          : null,
                      // Só envia ao soltar o dedo, para não inundar o broker.
                      onChangeEnd: podeControlar
                          ? (v) {
                              setState(() => _brilhoArrastando = null);
                              _enviar(brilho: v.round());
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
                            selecionada:
                                EstadoLampada.rgbDe(opcao).toString() ==
                                EstadoLampada.rgbDe(cor).toString(),
                            habilitada: podeControlar,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: matiz,
                      max: 360,
                      activeColor: HSVColor.fromAHSV(1, matiz, 1, 1).toColor(),
                      onChanged: podeControlar
                          ? (v) => setState(() => _matizArrastando = v)
                          : null,
                      onChangeEnd: podeControlar
                          ? (v) {
                              setState(() => _matizArrastando = null);
                              _enviar(
                                cor: HSVColor.fromAHSV(1, v, 1, 1).toColor(),
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
      onTap: habilitada ? () => _enviar(cor: cor) : null,
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
