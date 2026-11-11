# Funcionalidades e fluxos de uso

## Autenticação

### Login por e-mail

O usuário informa e-mail e senha. O serviço faz login no Firebase Auth,
recarrega o usuário e bloqueia a sessão se o e-mail ainda não estiver
verificado. A tela traduz erros comuns para mensagens em português.

### Cadastro

O cadastro cria uma conta, salva nome/e-mail no documento do usuário, atualiza
o nome de exibição e envia e-mail de verificação. Se a sincronização do perfil
ou o envio do e-mail falhar, o código tenta remover a conta recém-criada e
propaga o erro.

### Google e recuperação de senha

O Google usa popup na web e `GoogleSignIn` nas plataformas nativas. Após o
login, o perfil é criado ou atualizado sem apagar cidade e demais campos
existentes. A tela de login também envia link de redefinição de senha e
permite reenviar a verificação.

## Dashboard

O dashboard:

- mostra contagens de dispositivos e dispositivos ligados;
- agrupa visualmente dispositivos por ambiente;
- permite ligar/desligar dispositivos persistidos;
- abre as telas dos cinco destinos da navegação;
- permite sair da sessão sem apagar os dados do Firestore.

Os quatro ambientes iniciais (`Sala de estar`, `Quarto`, `Cozinha` e
`Banheiro`) são definidos no estado da tela. A persistência de ambientes não
existe como coleção ou serviço independente.

## Dispositivos

A tela permite:

- pesquisar e filtrar por ambiente;
- ordenar por nome;
- cadastrar por categoria ou pela busca de um modelo;
- escolher iluminação, tomada ou outro tipo;
- editar nome, identificador, tipo e ambiente;
- alternar o estado ligado/desligado;
- atualizar status de conexão;
- excluir um dispositivo.

O cadastro visual retorna um `DispositivoListaItem` ao dashboard, que então
gera um identificador `app-...` e chama o serviço Firestore. A validação
impede nome vazio, nomes duplicados no formulário e campos fora dos limites
do serviço.

## Automações

A tela apresenta três categorias: lâmpada, tomada smart e Raspberry Hub.
Para lâmpadas há cenas (`Leitura`, `Relaxar`, `Cinema` e `Foco`), brilho,
temperatura de cor, escolha de cor, temporizador e agenda semanal. Para
tomadas há potência, tensão, consumo estimado e desligamento imediato.

Esses controles são estado local. O consumo é calculado por uma estimativa
baseada em watts e tempo ligado; não é leitura de sensor. O Raspberry Hub e
seus serviços (Home Assistant, MQTT Broker e Pi-hole) são explicitamente
ilustrativos e não executam comandos reais.

## Alertas

`AlertasData` mantém uma lista em memória, o conjunto de alertas lidos e o
filtro de somente não lidas. A tela filtra alertas por todas, críticas,
dispositivos ou energia, agrupa por data e oferece navegação para a área
relacionada.

Não há coleção Firestore nem recebimento de notificações push implementado
para alertas.

## Perfil

O perfil exibe informações do usuário autenticado, resumo de ambientes e
dispositivos, configurações de aparência e cidade. A cidade é carregada e
salva no documento `usuarios/{uid}`. O tema pode seguir o sistema, ser claro
ou escuro. O logout é delegado ao dashboard.

