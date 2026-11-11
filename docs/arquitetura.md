# Arquitetura e organização do código

## Fluxo de inicialização

1. [`main.dart`](../pi_vi/lib/main.dart) garante a inicialização do Flutter.
2. O Firebase é inicializado com `DefaultFirebaseOptions.currentPlatform`.
3. Na web, a persistência local do Firebase Auth é habilitada.
4. `COSApp` cria os temas claro/escuro.
5. `_VerificadorDeSessao` restaura a sessão.
6. Usuários autenticados e verificados seguem para `DashboardScreen`; os
   demais passam pela `SplashScreen` e depois pelo login.

Contas criadas com e-mail precisam estar verificadas. Usuários autenticados
por outro provedor não passam por essa validação de e-mail.

## Camadas

### Entrada e apresentação

- `lib/main.dart`: inicialização, tema raiz e decisão inicial de sessão.
- `lib/screens/`: telas completas e seus estados locais.
- `lib/widgets/cos_app_navigation.dart`: cabeçalho e navegação inferior
  compartilhada.
- `lib/theme.dart`: paleta COS e `ValueNotifier` do tema.

### Modelos e estado

- `models/dispositivo_iot.dart`: representação e conversão de documentos
  Firestore.
- `models/alerta.dart`: tipos de alerta e estado de leitura em memória.
- `AutomacaoData`, em `screens/automacao.dart`: estado local de energia,
  brilho, temperatura, cor, temporizador, agenda e consumo estimado.

### Serviços

- `FirebaseService`: operações de autenticação por e-mail, perfil e sessão.
- `SocialAuthService`: login Google e sincronização do perfil.
- `DispositivoIotService`: CRUD, stream e atualizações de estado no Firestore.

Não há um gerenciador de estado global ou roteador declarado; a navegação usa
`Navigator` e callbacks entre telas. O dashboard mantém as instâncias de
`AutomacaoData` e `AlertasData` enquanto a sessão da tela está ativa.

## Navegação

A barra inferior possui cinco destinos:

1. Início
2. Dispositivos
3. Automações
4. Alertas
5. Perfil

O dashboard centraliza a navegação e fornece os dados necessários às telas.
Login, cadastro e splash usam rotas empilhadas/removidas diretamente com
`MaterialPageRoute`.

## Convenções de dados

Datas vindas do Firestore são convertidas de `Timestamp` para `DateTime`.
Campos desconhecidos ou formatos inválidos não são silenciosamente corrigidos
no modelo: uma data inválida causa `FormatException`.

