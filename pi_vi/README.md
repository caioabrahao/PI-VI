# pi_vi

A new Flutter project.

## Cadastro de dispositivos IoT

Os dispositivos IoT cadastrados são persistidos no Cloud Firestore em
`usuarios/{uid}/dispositivosIot/{deviceId}`. O serviço
`DispositivoIotService` oferece cadastro, consulta em tempo real,
atualização dos dados e do status de conexão, e remoção. Os registros incluem
nome, identificador único do dispositivo (por exemplo, número de série), tipo
(como luz ou tomada), ambiente opcional, status e datas de criação/atualização.

Os dados ficam separados por usuário autenticado. As regras em `firestore.rules`
restringem o acesso ao proprietário e validam os campos; publique-as no projeto
Firebase configurado antes de usar o serviço:

```bash
firebase deploy --only firestore:rules
```

Esse backend registra os metadados e o último status de conexão informado pelo
aplicativo. Comunicação com os dispositivos e envio de comandos de controle
dependem da integração futura com o hardware e o protocolo adotado.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
