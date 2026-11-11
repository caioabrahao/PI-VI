// Escolhe, em tempo de compilação, qual cliente MQTT usar:
// - Android/iOS/desktop: MqttServerClient (TCP + TLS, porta 8883)
// - Web: MqttBrowserClient (WebSocket + TLS, porta 8084)
//
// Parecido com uma interface Java com duas implementações, só que quem
// escolhe é o compilador, conforme a plataforma.
export 'cliente_mqtt_stub.dart'
    if (dart.library.io) 'cliente_mqtt_io.dart'
    if (dart.library.js_interop) 'cliente_mqtt_web.dart';
