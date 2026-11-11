# Visão geral

## O que é o projeto

O COS HUB é um aplicativo Flutter para organizar ambientes de uma casa e
gerenciar dispositivos IoT. A interface foi construída para funcionar em
múltiplas plataformas e usa Firebase Authentication e Cloud Firestore.

O repositório contém principalmente o cliente Flutter. O protótipo de hardware,
o firmware do ESP32, um broker MQTT e uma API própria não estão presentes na
árvore atual do projeto.

## Objetivos atuais

- Permitir cadastro e login de usuários.
- Manter os dados de cada usuário separados no Firestore.
- Cadastrar, listar, editar, ligar/desligar e excluir dispositivos IoT.
- Organizar dispositivos por ambientes exibidos no dashboard.
- Oferecer telas de automação, alertas e perfil.
- Manter uma identidade visual COS com temas claro, escuro e automático.

## Tecnologias

| Tecnologia | Uso observado |
|---|---|
| Flutter e Dart | Interface, navegação, estado local e testes |
| Firebase Core | Inicialização do Firebase |
| Firebase Authentication | E-mail/senha, verificação de e-mail e Google |
| Cloud Firestore | Perfil e dispositivos IoT |
| FlutterFire | Configurações por plataforma |
| Google Sign-In | Login Google em plataformas compatíveis |
| Material 3 | Componentes e temas da interface |
| `flutter_test` | Testes unitários e widget |

MQTT, ESP32, Wokwi e HiveMQ aparecem no planejamento do README, mas não têm
implementação correspondente em `lib/`.

## Plataformas configuradas

O arquivo `firebase_options.dart` contém configurações para Android, iOS,
macOS, web e Windows. Linux está explicitamente rejeitado em tempo de execução
por não possuir configuração Firebase. A pasta contém os runners nativos de
Android, iOS, macOS, Linux, Windows e web, mas a cobertura funcional não é
uniforme entre eles.

## Nomenclatura

O pacote Flutter ainda se chama `pi_vi`, enquanto a marca apresentada na
interface é COS/COS HUB. O nome exibido também varia nos metadados nativos:
Android usa `pi_vi`, iOS usa `Pi Vi` e a aplicação Flutter usa
`COS - Casa Inteligente`.

