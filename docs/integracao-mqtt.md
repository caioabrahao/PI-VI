# Integração com a lâmpada SmartLight (MQTT)

O app conversa **direto com o broker MQTT** (EMQX Serverless), sem backend no meio.
O Firestore continua guardando só o cadastro do dispositivo.

## Tópicos e mensagens

Cada lâmpada usa `smartlight/<identificador>/...`:

| Tópico | Quem publica | Conteúdo |
|---|---|---|
| `CMD` | app | Comando parcial: `{"ligado":true}`, `{"brilho":50}`, `{"rgb":[255,0,0]}` |
| `STATUS` | lâmpada (retained) | Estado completo: `{"ligado":true,"brilho":75,"rgb":[255,120,0]}` |
| `AVAILABILITY` | lâmpada (retained + LWT) | `{"online":true}` / `{"online":false}` |

`brilho` vai de 10 a 100 (%). O app assina `smartlight/+/STATUS` e
`smartlight/+/AVAILABILITY` e, por serem *retained*, recebe o último estado
assim que conecta.

## Qual dispositivo usa MQTT

Uma lâmpada cujo `identificador` **não** começa com `app-` (ex.: `raphael-01`,
`sl-a1b2c3d4e5f6`). Para ela, `ligado` e `statusConexao` vêm ao vivo do MQTT
(`ServicoMqtt.aplicarEstado`) e o liga/desliga publica em `CMD`. Os demais
dispositivos seguem só no Firestore.

Na tela de cadastro, ao escolher "Lâmpada", preencha o campo
"ID da SmartLight". Um dispositivo já existente pode ter o identificador
alterado pelo menu "Editar". Tocar no card da lâmpada abre a tela de controle
(liga/desliga, brilho e cor).

## Conexão

| Plataforma | Cliente (`mqtt_client`) | Endereço |
|---|---|---|
| Android/iOS/desktop | `MqttServerClient` | TLS, porta 8883 |
| Web | `MqttBrowserClient` | `wss://<host>:8084/mqtt` |

A escolha é feita por import condicional em `lib/services/mqtt/cliente_mqtt.dart`.

## Credenciais

Usuário e senha do broker **não ficam no código**. Crie `pi_vi/mqtt.json`
(já está no `.gitignore`) a partir de `mqtt.example.json` e rode:

```bash
flutter run --dart-define-from-file=mqtt.json
```

Sem esse arquivo o app funciona normalmente, mas as lâmpadas aparecem como
"MQTT não configurado".

## Limitações

- A senha MQTT do app vai embutida no binário. Aceitável para o MVP; o ideal
  é um backend emitindo credenciais por usuário.
- Cadastro pelo pareamento BLE (ID `sl-<mac>` lido da lâmpada) ainda não foi
  implementado.
