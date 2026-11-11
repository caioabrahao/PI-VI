# Fundamentação teórica

## 1. Contexto de Engenharia de Software

Engenharia de Software é a aplicação sistemática de processos, métodos,
técnicas e ferramentas para especificar, desenvolver, testar, manter e
evoluir software com qualidade. No COS HUB, essa abordagem é necessária
porque o produto combina interface multiplataforma, autenticação, persistência
em nuvem e, futuramente, comunicação com dispositivos IoT.

### 1.1 Requisitos de software

Requisitos descrevem o que o sistema deve fazer e as restrições sob as quais
deve operar.

- **Requisitos funcionais:** representam comportamentos observáveis, como
  cadastrar um dispositivo, autenticar um usuário, alterar seu estado e
  consultar os dispositivos em tempo real.
- **Requisitos não funcionais:** representam atributos de qualidade, como
  segurança, disponibilidade, usabilidade, responsividade, desempenho e
  compatibilidade entre plataformas.

No código atual, os requisitos funcionais aparecem principalmente nas telas de
login, dashboard, dispositivos, automações, alertas e perfil. As regras do
Firestore representam parte dos requisitos de segurança e integridade dos
dados.

### 1.2 Ciclo de vida e desenvolvimento incremental

O desenvolvimento incremental divide o produto em partes que podem ser
implementadas e validadas progressivamente. Essa estratégia é adequada a um
MVP porque permite entregar primeiro autenticação, cadastro e gerenciamento de
dispositivos, deixando integrações mais complexas, como MQTT e hardware,
para incrementos posteriores.

Cada incremento deve passar por análise, implementação, teste e revisão. A
documentação do projeto registra o estado implementado e separa as
funcionalidades planejadas das funcionalidades efetivamente disponíveis.

### 1.3 Qualidade de software

Qualidade não significa apenas ausência de erros. Ela inclui adequação
funcional, confiabilidade, usabilidade, eficiência, manutenibilidade e
portabilidade. O projeto aplica algumas práticas relacionadas a esses
atributos:

- separação entre telas, modelos, serviços e widgets;
- validação de dados antes de gravá-los;
- tratamento de erros de autenticação e operações remotas;
- testes unitários e de widgets;
- uso do analyzer e das regras `flutter_lints`;
- suporte a diferentes plataformas pelo Flutter.

## 2. Flutter e Dart

### 2.1 Flutter

Flutter é um framework de interface desenvolvido pelo Google. Em vez de
delegar toda a renderização a componentes nativos específicos, ele utiliza
uma árvore própria de widgets e renderiza a interface de forma consistente
nas plataformas suportadas.

Essa abordagem permite compartilhar grande parte do código entre Android, iOS,
web, Windows, macOS e Linux. No COS HUB, as telas são construídas com
`MaterialApp`, `Scaffold`, formulários, listas, diálogos, barras de navegação
e componentes Material 3.

### 2.2 Widgets e composição

Um widget descreve uma parte da interface e suas propriedades. Widgets podem
ser compostos em árvores maiores, o que favorece reutilização e separação de
responsabilidades.

- `StatelessWidget` é usado quando a saída depende apenas das propriedades
  recebidas.
- `StatefulWidget` é usado quando a tela precisa manter estado mutável, como
  filtros, carregamento, formulários ou seleção de dispositivos.
- `BuildContext` permite acessar o tema, a árvore de widgets e recursos do
  ambiente atual.

O projeto usa essa composição em `DashboardScreen`, `DispositivoScreen`,
`AutomacaoScreen`, `AlertasScreen`, `PerfilScreen` e no widget de navegação
compartilhado.

### 2.3 Dart e programação assíncrona

Dart é a linguagem utilizada pelo Flutter. O projeto usa:

- classes e enumeradores para modelar dados e categorias;
- null safety para declarar valores que podem ou não existir;
- `Future` para operações assíncronas que terminam uma vez;
- `Stream` para sequências contínuas de eventos;
- `async`/`await` para tornar operações remotas legíveis;
- `try`/`catch` para propagar e tratar falhas.

O cadastro e a autenticação retornam `Future`. Já a observação de dispositivos
usa um `Stream<List<DispositivoIot>>`, que recebe atualizações do Firestore
enquanto a tela estiver inscrita.

## 3. Arquitetura do aplicativo

### 3.1 Separação de responsabilidades

Separar responsabilidades reduz acoplamento e facilita testes e manutenção.
No COS HUB:

- **telas** cuidam da apresentação e da interação;
- **modelos** representam entidades e convertem dados;
- **serviços** encapsulam autenticação e acesso ao Firestore;
- **widgets** concentram componentes reutilizáveis;
- **tema** centraliza cores, tipografia e modo claro/escuro.

Essa organização se aproxima de uma arquitetura em camadas. Ela não é uma
implementação formal de Clean Architecture ou MVC completo, portanto novos
fluxos devem preservar a separação existente sem atribuir responsabilidades
de persistência diretamente a componentes visuais.

### 3.2 Navegação e fluxo de telas

O `Navigator` gerencia uma pilha de rotas. Abrir uma tela adiciona uma rota;
voltar remove a rota; `pushReplacement` substitui a tela atual; e
`pushAndRemoveUntil` pode remover o histórico, como ocorre ao entrar no
dashboard após o login.

A navegação inferior usa callbacks de índice. O dashboard interpreta esses
índices e apresenta a tela correspondente, mantendo dados compartilhados da
sessão, como a instância de automações e a coleção de alertas.

### 3.3 Gerenciamento de estado

Estado é a informação que pode mudar durante a execução e alterar a interface.
O projeto utiliza mecanismos simples e adequados ao escopo atual:

- `setState` para estado privado de uma tela;
- `ValueNotifier<ThemeMode>` para o modo visual global;
- `ChangeNotifier` em `AlertasData`;
- assinatura de `Stream` para dispositivos remotos;
- objetos de estado locais em `AutomacaoData`.

O estado de automações e alertas permanece em memória e é perdido ao encerrar
a sessão ou reconstruir o fluxo. Ele não deve ser confundido com persistência
no Firestore.

## 4. Firebase e computação em nuvem

### 4.1 Backend como serviço

Backend as a Service (BaaS) é um modelo no qual serviços prontos fornecem
autenticação, banco de dados e infraestrutura, reduzindo a necessidade de
implementar e operar um servidor próprio. O Firebase é utilizado pelo COS HUB
como BaaS.

O aplicativo inicializa o Firebase com configurações específicas de cada
plataforma. Essas configurações identificam o projeto, mas a autorização real
depende das regras do Firestore e das configurações do Authentication.

### 4.2 Firebase Authentication

Autenticação é o processo de verificar a identidade de um usuário. O Firebase
Authentication fornece a sessão e o identificador único (`uid`) usados pelo
aplicativo.

O projeto utiliza:

- e-mail e senha;
- verificação de e-mail;
- recuperação de senha;
- login com Google;
- persistência local da sessão na web.

Autenticação não é o mesmo que autorização: o login confirma quem é o usuário;
as regras do Firestore determinam o que ele pode acessar.

### 4.3 Cloud Firestore

Firestore é um banco de dados NoSQL orientado a documentos. Em vez de tabelas
e linhas relacionais, ele organiza documentos em coleções e subcoleções.
Documentos armazenam campos tipados e podem ser consultados ou observados em
tempo real.

O COS HUB utiliza:

```text
usuarios/{uid}
usuarios/{uid}/dispositivosIot/{deviceId}
```

O identificador do usuário no caminho funciona como fronteira lógica dos
dados. O serviço implementa as operações fundamentais de CRUD:

- **Create:** `cadastrar`;
- **Read:** `obter` e `observarDispositivos`;
- **Update:** `atualizarCadastro`, `alterarEstado` e
  `atualizarStatusConexao`;
- **Delete:** `excluir`.

### 4.4 Consultas em tempo real e consistência

Uma consulta em tempo real mantém uma inscrição aberta e emite novos
resultados quando os documentos observados mudam. Isso permite que dashboard
e tela de dispositivos reflitam alterações sem uma atualização manual.

Timestamps do servidor evitam depender exclusivamente do relógio do aparelho.
Ainda assim, o sistema precisa tratar indisponibilidade de rede, conflitos,
documentos ausentes e divergências entre o modelo local e as regras publicadas.

## 5. Segurança e integridade

### 5.1 Autorização por proprietário

As regras do Firestore usam `request.auth.uid == uid` para restringir o
acesso ao documento do próprio usuário. Esse padrão é uma forma de controle de
acesso baseado em identidade e propriedade do recurso.

### 5.2 Validação de entrada

Validação de entrada verifica se os dados recebidos obedecem ao contrato
esperado antes do processamento ou armazenamento. O serviço de dispositivos:

- remove espaços das extremidades;
- rejeita valores vazios;
- aplica limites de tamanho;
- restringe status de conexão a valores conhecidos;
- evita identificadores duplicados por usuário;
- verifica o tipo e o formato de datas ao ler documentos.

A validação no cliente melhora a experiência, mas não substitui a validação
no servidor. Por isso, as regras Firestore também devem conferir campos,
tipos, tamanhos e timestamps.

### 5.3 Princípio do menor privilégio

O menor privilégio determina que cada usuário, serviço ou componente receba
somente as permissões necessárias. A separação por `uid` segue esse princípio
para os dispositivos, mas regras amplas no documento de perfil devem ser
reavaliadas quando novos campos ou papéis de usuário forem adicionados.

## 6. Internet das Coisas e tecnologias planejadas

### 6.1 IoT

Internet das Coisas (IoT) é a integração de objetos físicos com sensores,
atuadores, conectividade e software. Um sistema IoT normalmente possui:

1. dispositivo físico;
2. firmware;
3. rede e protocolo de comunicação;
4. serviço de backend ou broker;
5. interface para monitoramento e controle.

No estado atual, o aplicativo implementa o cadastro e o estado lógico dos
dispositivos. O firmware, o hardware e a comunicação física ainda não estão
presentes no código Flutter.

### 6.2 ESP32

ESP32 é uma família de microcontroladores com conectividade Wi-Fi e Bluetooth,
adequada a protótipos IoT. Ele pode ler sensores, controlar atuadores e
enviar eventos para um serviço remoto por meio de firmware.

No escopo planejado, o ESP32 poderia controlar uma lâmpada e reportar
conectividade e estado. Essa integração exige firmware, credenciais de rede,
tratamento de falhas e um contrato de mensagens, nenhum dos quais está
implementado no repositório atual.

### 6.3 MQTT

MQTT é um protocolo leve de mensagens baseado em publicação e assinatura
(publish/subscribe). Clientes publicam mensagens em tópicos; outros clientes
assinam esses tópicos por meio de um broker.

Uma possível separação conceitual seria:

```text
cos/{uid}/{deviceId}/comando
cos/{uid}/{deviceId}/estado
cos/{uid}/{deviceId}/conexao
```

O tópico de comando transportaria a intenção do aplicativo; os tópicos de
estado e conexão permitiriam confirmar o resultado. Essa definição é apenas
teórica no estado atual: não há broker, cliente MQTT, tópico ou ponte entre
Firestore e MQTT no código.

### 6.4 Wokwi e HiveMQ

Wokwi é uma plataforma de simulação de microcontroladores e circuitos. Ela
permite testar lógica de firmware sem o hardware físico.

HiveMQ é uma plataforma e um conjunto de ferramentas relacionados a brokers e
testes MQTT. Ambos aparecem como tecnologias planejadas no projeto, mas não
possuem integração verificável na árvore atual.

## 7. Testes e técnicas de validação

### 7.1 Testes unitários

Testes unitários verificam unidades pequenas e isoladas, como funções, classes
ou conversores. O teste de `DispositivoIot.fromFirestore` verifica conversão
de timestamps e rejeição de datas inválidas.

### 7.2 Testes de widgets

Testes de widgets montam uma árvore Flutter em memória e simulam ações do
usuário, como toque, rolagem e preenchimento de formulário. O projeto usa
essa técnica para validar cadastro de dispositivos, dashboard e automações sem
depender necessariamente de um dispositivo físico.

### 7.3 Pirâmide de testes

A pirâmide de testes recomenda uma base maior de testes rápidos e isolados,
seguida por testes de integração e uma quantidade menor de testes
end-to-end. O projeto atual possui principalmente testes unitários e de
widgets; ainda faltam testes de integração com Firebase, regras de segurança,
autenticação real e hardware.

### 7.4 Análise estática

Análise estática examina o código sem executá-lo. O `flutter analyze` e o
`flutter_lints` ajudam a encontrar erros, problemas de estilo e padrões
arriscados antes da execução. Essa técnica complementa os testes, mas não
prova sozinha que os fluxos funcionais estão corretos.

## 8. Resumo da aplicação teórica

O COS HUB aplica Flutter/Dart para uma interface multiplataforma, uma
arquitetura em camadas para separar apresentação e acesso a dados, Firebase
como BaaS, Authentication para identidade, Firestore como banco NoSQL e
streams para atualização em tempo real. Validação, regras de autorização,
análise estática e testes de widgets apoiam a qualidade do MVP.

ESP32, MQTT, Wokwi e HiveMQ fornecem a base conceitual para a futura camada
IoT, mas devem ser tratados como tecnologias planejadas até que firmware,
broker, contrato de mensagens e integração com o aplicativo sejam adicionados
ao projeto.

