# Testes e validação

## Como executar

Na pasta `pi_vi/`:

```powershell
flutter test
```

Também é possível executar um arquivo específico:

```powershell
flutter test test/dispositivo_iot_test.dart
```

## Cobertura atual

### Modelo de dispositivo

`dispositivo_iot_test.dart` verifica:

- conversão de `Timestamp` para `DateTime`;
- leitura dos campos principais;
- rejeição de datas inválidas com `FormatException`.

### Tela de dispositivos

`dispositivo_screen_test.dart` cobre:

- opções de cadastro;
- cadastro de lâmpada;
- cadastro de modelo desconhecido em “Outros”;
- rejeição de nome duplicado;
- validação de nome obrigatório;
- armazenamento correto em `DispositivoListaItem`.

Esses testes evitam autenticação e Firestore, validando a camada visual e o
retorno do formulário.

### Dashboard

`widget_test.dart` verifica:

- conexão de um dispositivo a um ambiente;
- exclusão de ambiente com dispositivos após duas confirmações.

### Automações

`automacao_screen_test.dart` cobre:

- categorias e dispositivos exibidos;
- aplicação de uma cena;
- seleção de cor;
- registro de consumo estimado;
- seleção de Raspberry Hub e mensagens demonstrativas;
- controles de tomada e navegação inferior.

## Limitações da suíte

Não há testes de integração contra Firebase Emulator Suite ou um projeto
Firebase real. Também não há testes de regras Firestore, login Google,
recuperação de senha, deploy, MQTT, hardware ou compatibilidade visual entre
plataformas. Portanto, `flutter test` valida principalmente modelos, widgets e
estado local.

## Critério recomendado para novas mudanças

Para cada mudança:

1. executar o teste mais próximo do fluxo alterado;
2. executar `flutter analyze`;
3. executar `flutter test` antes de abrir uma entrega;
4. adicionar teste quando um novo fluxo ou regra de validação for introduzido.

