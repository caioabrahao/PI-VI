import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../../config/mqtt_config.dart';

/// Cliente para a versão web: o navegador só permite WebSocket,
/// então usamos `wss://` (WebSocket com TLS) na porta 8084.
MqttClient criarClienteMqtt(String idCliente) {
  final cliente = MqttBrowserClient.withPort(
    'wss://${MqttConfig.host}${MqttConfig.caminhoWebSocket}',
    idCliente,
    MqttConfig.portaWebSocket,
  );
  cliente.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return cliente;
}
