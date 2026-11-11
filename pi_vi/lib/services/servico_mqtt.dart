import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../config/mqtt_config.dart';
import '../models/dispositivo_iot.dart';
import '../models/estado_lampada.dart';
import 'mqtt/cliente_mqtt.dart';

enum StatusMqtt { semConfiguracao, desconectado, conectando, conectado, erro }

/// Conversa com as lâmpadas SmartLight pelo broker MQTT.
///
/// É o "irmão" da classe ServicoMqtt do firmware, só que do lado do app:
/// - publica comandos em `smartlight/<id>/CMD`;
/// - escuta `smartlight/+/STATUS` e `smartlight/+/AVAILABILITY` de TODAS as
///   lâmpadas com uma assinatura só (o `+` é curinga de um nível).
///
/// Como a lâmpada publica STATUS e AVAILABILITY com `retain`, o broker
/// entrega o último valor assim que o app assina. Ou seja: abriu o app,
/// já sabe se a lâmpada está ligada e online.
///
/// Uma instância única para o app inteiro (singleton), parecido com um
/// `static` + construtor privado no Java.
class ServicoMqtt {
  ServicoMqtt._();

  static final ServicoMqtt instancia = ServicoMqtt._();

  static const Duration _intervaloNovaTentativa = Duration(seconds: 10);

  MqttClient? _cliente;
  Future<void>? _conexaoEmAndamento;
  Timer? _novaTentativa;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _assinatura;

  final Map<String, EstadoLampada> _estados = {};
  final Map<String, bool> _disponibilidade = {};

  /// Estado da conexão com o broker, para mostrar na interface.
  final ValueNotifier<StatusMqtt> status = ValueNotifier(
    MqttConfig.configurado
        ? StatusMqtt.desconectado
        : StatusMqtt.semConfiguracao,
  );

  final StreamController<String> _mudancas = StreamController.broadcast();

  /// Emite o identificador da lâmpada sempre que o estado ou a
  /// disponibilidade dela mudar.
  Stream<String> get mudancas => _mudancas.stream;

  bool get conectado => status.value == StatusMqtt.conectado;

  EstadoLampada? estadoDe(String identificador) => _estados[identificador];

  /// `true` = online, `false` = offline, `null` = ainda não sabemos.
  bool? disponibilidadeDe(String identificador) =>
      _disponibilidade[identificador];

  /// Conecta ao broker se ainda não estiver conectado.
  /// Pode ser chamado várias vezes: só a primeira chamada abre a conexão.
  Future<void> garantirConexao() {
    if (!MqttConfig.configurado) {
      status.value = StatusMqtt.semConfiguracao;
      return Future.value();
    }
    if (conectado) return Future.value();
    return _conexaoEmAndamento ??= _conectar().whenComplete(() {
      _conexaoEmAndamento = null;
    });
  }

  Future<void> _conectar() async {
    _novaTentativa?.cancel();
    status.value = StatusMqtt.conectando;

    final cliente = criarClienteMqtt(_gerarIdCliente())
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..logging(on: false)
      ..onConnected = _aoConectar
      ..onAutoReconnected = _aoConectar
      ..onDisconnected = _aoDesconectar;

    cliente.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(cliente.clientIdentifier)
        .startClean();

    try {
      await cliente.connect(MqttConfig.usuario, MqttConfig.senha);
    } catch (e) {
      debugPrint('MQTT: falha ao conectar: $e');
      cliente.disconnect();
      status.value = StatusMqtt.erro;
      _agendarNovaTentativa();
      return;
    }

    if (cliente.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('MQTT: conexão recusada: ${cliente.connectionStatus}');
      cliente.disconnect();
      status.value = StatusMqtt.erro;
      _agendarNovaTentativa();
      return;
    }

    _cliente = cliente;
    _assinatura = cliente.updates?.listen(_aoReceberMensagens);

    final todasLampadas = '${MqttConfig.prefixoTopico}/+';
    cliente.subscribe(
      '$todasLampadas/${MqttConfig.sufixoEstado}',
      MqttQos.atLeastOnce,
    );
    cliente.subscribe(
      '$todasLampadas/${MqttConfig.sufixoDisponibilidade}',
      MqttQos.atLeastOnce,
    );

    status.value = StatusMqtt.conectado;
  }

  void _agendarNovaTentativa() {
    _novaTentativa?.cancel();
    _novaTentativa = Timer(_intervaloNovaTentativa, garantirConexao);
  }

  void _aoConectar() {
    status.value = StatusMqtt.conectado;
  }

  void _aoDesconectar() {
    // Com autoReconnect ligado, a biblioteca tenta voltar sozinha.
    if (status.value == StatusMqtt.conectado) {
      status.value = StatusMqtt.conectando;
    }
    _avisarTodas();
  }

  /// Fecha a conexão (por exemplo, ao sair da conta).
  Future<void> desconectar() async {
    _novaTentativa?.cancel();
    await _assinatura?.cancel();
    _assinatura = null;
    _cliente?.autoReconnect = false;
    _cliente?.disconnect();
    _cliente = null;
    _estados.clear();
    _disponibilidade.clear();
    status.value = MqttConfig.configurado
        ? StatusMqtt.desconectado
        : StatusMqtt.semConfiguracao;
    _avisarTodas();
  }

  /// Envia um comando parcial para a lâmpada, por exemplo
  /// `{"ligado": true}` ou `{"brilho": 50, "rgb": [255, 0, 0]}`.
  ///
  /// Não mexemos no estado local aqui: quem confirma a mudança é a própria
  /// lâmpada, publicando o novo STATUS. Assim a tela mostra sempre o estado
  /// real, inclusive quando alguém gira o encoder.
  void publicarComando(String identificador, Map<String, dynamic> comando) {
    final cliente = _cliente;
    if (cliente == null || !conectado) {
      throw StateError('Sem conexão com o broker MQTT.');
    }

    final payload = MqttClientPayloadBuilder()
      ..addUTF8String(jsonEncode(comando));

    cliente.publishMessage(
      MqttConfig.topicoComando(identificador),
      MqttQos.atLeastOnce,
      payload.payload!,
    );
  }

  void _aoReceberMensagens(List<MqttReceivedMessage<MqttMessage>> mensagens) {
    for (final mensagem in mensagens) {
      final publicacao = mensagem.payload;
      if (publicacao is! MqttPublishMessage) continue;

      final partes = mensagem.topic.split('/');
      if (partes.length != 3 || partes[0] != MqttConfig.prefixoTopico) {
        continue;
      }

      final identificador = partes[1];
      final sufixo = partes[2];

      final Object? json;
      try {
        json = jsonDecode(utf8.decode(publicacao.payload.message));
      } on FormatException {
        debugPrint('MQTT: JSON inválido em ${mensagem.topic}');
        continue;
      }
      if (json is! Map<String, dynamic>) continue;

      if (sufixo == MqttConfig.sufixoEstado) {
        final estado = EstadoLampada.doJson(json);
        if (estado == null) continue;
        _estados[identificador] = estado;
      } else if (sufixo == MqttConfig.sufixoDisponibilidade) {
        final online = json['online'];
        if (online is! bool) continue;
        _disponibilidade[identificador] = online;
      } else {
        continue;
      }

      _mudancas.add(identificador);
    }
  }

  void _avisarTodas() {
    for (final identificador in {..._estados.keys, ..._disponibilidade.keys}) {
      _mudancas.add(identificador);
    }
  }

  /// Junta o cadastro do Firestore com o estado ao vivo do MQTT.
  /// Para lâmpadas SmartLight, `ligado` e `statusConexao` vêm da lâmpada.
  DispositivoIot aplicarEstado(DispositivoIot dispositivo) {
    if (!dispositivo.usaMqtt) return dispositivo;

    final id = dispositivo.identificador;
    final estado = _estados[id];
    final online = conectado ? _disponibilidade[id] : null;

    return dispositivo.copyWith(
      ligado: estado?.ligado ?? false,
      statusConexao: switch (online) {
        true => 'conectado',
        false => 'desconectado',
        null => 'desconhecido',
      },
    );
  }

  static String _gerarIdCliente() {
    final aleatorio = Random();
    final sufixo = List.generate(
      8,
      (_) => aleatorio.nextInt(16).toRadixString(16),
    ).join();
    return 'cos-hub-$sufixo';
  }
}
