# Ambiente de desenvolvimento e execução

## Pré-requisitos

- Git;
- Flutter SDK compatível com Dart `^3.11.5`;
- Android Studio ou Visual Studio Code para desenvolvimento mobile;
- navegador compatível para web;
- Firebase configurado conforme [Firebase e dados](./firebase-e-dados.md).

O diretório de trabalho do app é `pi_vi/`, e os comandos Flutter devem ser
executados a partir dele.

## Instalação

```powershell
cd pi_vi
flutter pub get
flutter doctor
```

## Executar

```powershell
flutter run
flutter run -d chrome
```

O primeiro comando usa o dispositivo ou emulador selecionado pelo Flutter. O
segundo inicia a versão web no Chrome.

## Build

```powershell
flutter build web
flutter build apk
```

Os runners nativos também permitem builds para iOS, macOS e Windows quando o
ambiente correspondente estiver instalado. Linux não está configurado no
Firebase e não deve ser tratado como plataforma funcional sem configuração
adicional.

## Dependências principais

As dependências de runtime estão declaradas em `pubspec.yaml`:

- `firebase_core`;
- `firebase_auth`;
- `cloud_firestore`;
- `google_sign_in`;
- `font_awesome_flutter`;
- `cupertino_icons`.

`flutter_lints` e `flutter_test` são dependências de desenvolvimento.

## Qualidade estática

O analyzer usa `flutter_lints` e exclui os diretórios de runners nativos e
artefatos de build:

```powershell
flutter analyze
```

Alterações no projeto devem preservar as regras de lint e evitar editar
arquivos gerados, como `pubspec.lock` ou configurações geradas, sem motivo
explícito.

