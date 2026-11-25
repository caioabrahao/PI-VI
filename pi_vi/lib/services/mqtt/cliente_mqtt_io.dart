import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../config/mqtt_config.dart';

/// Cliente para Android, iOS e desktop: MQTT puro sobre TLS (porta 8883).
///
/// O certificado do EMQX Serverless é assinado pela DigiCert, que já está
/// na lista de autoridades confiáveis do sistema, então não precisamos
/// embutir o CA aqui (diferente do ESP32).
MqttClient criarClienteMqtt(String idCliente) {
  final cliente = MqttServerClient.withPort(
    MqttConfig.host,
    idCliente,
    MqttConfig.portaTls,
  );
  cliente.secure = true;
  return cliente;
}
