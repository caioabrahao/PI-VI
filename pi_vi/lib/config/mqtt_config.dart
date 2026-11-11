/// Configuração do broker MQTT (EMQX Serverless) usado pelas lâmpadas SmartLight.
///
/// O host e as portas não são segredo. Usuário e senha NÃO ficam no código:
/// eles vêm do arquivo `mqtt.json` (fora do Git) passado na hora de rodar:
///
/// ```bash
/// flutter run --dart-define-from-file=mqtt.json
/// ```
///
/// Veja `mqtt.example.json` para o formato do arquivo.
class MqttConfig {
  MqttConfig._();

  static const String host = String.fromEnvironment(
    'MQTT_HOST',
    defaultValue: 't916f211.ala.us-east-1.emqxsl.com',
  );

  /// Porta MQTT com TLS (Android, iOS e desktop).
  static const int portaTls = int.fromEnvironment(
    'MQTT_PORTA_TLS',
    defaultValue: 8883,
  );

  /// Porta WebSocket com TLS (versão web).
  static const int portaWebSocket = int.fromEnvironment(
    'MQTT_PORTA_WSS',
    defaultValue: 8084,
  );

  /// Caminho do WebSocket no EMQX.
  static const String caminhoWebSocket = '/mqtt';

  static const String usuario = String.fromEnvironment('MQTT_USUARIO');
  static const String senha = String.fromEnvironment('MQTT_SENHA');

  /// Prefixo de todos os tópicos: `smartlight/<identificador>/<SUFIXO>`.
  static const String prefixoTopico = 'smartlight';

  static const String sufixoComando = 'CMD';
  static const String sufixoEstado = 'STATUS';
  static const String sufixoDisponibilidade = 'AVAILABILITY';

  static bool get configurado => usuario.isNotEmpty && senha.isNotEmpty;

  static String topicoComando(String identificador) =>
      '$prefixoTopico/$identificador/$sufixoComando';
}
