# COS HUB 💡
### Plataforma de Automação e Gerenciamento de Dispositivos IoT

O **COS HUB** é um projeto acadêmico desenvolvido no âmbito do Projeto Integrador VI da Pontifícia Universidade Católica de Campinas (PUC-Campinas). A proposta consiste no desenvolvimento de uma plataforma centralizada para organizar ambientes e controlar dispositivos de Internet das Coisas (IoT) por meio de uma aplicação multiplataforma.

O projeto busca integrar software, backend e hardware em uma solução que permita ao usuário gerenciar seus dispositivos inteligentes de maneira simples e intuitiva.

## 🎯 Objetivo do Projeto

Desenvolver um Produto Mínimo Viável (MVP) de uma plataforma de automação residencial que permita aos usuários organizar propriedades, cômodos e dispositivos IoT, além de controlar suas funcionalidades por meio de uma interface centralizada.

A aplicação será desenvolvida utilizando Flutter, com foco em dispositivos móveis e suporte a uma versão web responsiva.

## ✨ Funcionalidades

### 👤 Autenticação de Usuários
- Cadastro de novos usuários.
- Login e encerramento de sessão.
- Recuperação de senha.
- Controle de acesso aos dados de cada usuário.

### 🏠 Gerenciamento de Ambientes
- Organização de propriedades e cômodos.
- Cadastro, consulta, edição e remoção de ambientes.
- Associação de dispositivos aos respectivos cômodos.

### 📱 Gerenciamento de Dispositivos IoT
- Cadastro e configuração de dispositivos compatíveis.
- Consulta e atualização das informações dos dispositivos.
- Associação de dispositivos aos ambientes cadastrados.
- Exibição da disponibilidade e do último estado conhecido.

### 💡 Controle de Iluminação Inteligente
- Ligar e desligar a lâmpada.
- Ajustar a intensidade da iluminação.
- Selecionar cores RGB.
- Sincronizar o estado físico do dispositivo com o aplicativo.

### 🔌 Integração com Hardware
- Utilização do microcontrolador ESP32.
- Comunicação entre aplicação e dispositivo IoT.
- Troca de mensagens por meio do protocolo MQTT.
- Desenvolvimento e validação de um protótipo de lâmpada inteligente de baixa tensão.

### 🌐 Aplicação Multiplataforma
- Interface desenvolvida com Flutter.
- Suporte a dispositivos móveis.
- Versão web responsiva.
- Interface centralizada para gerenciamento dos dispositivos.

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Finalidade |
|---|---|
| Flutter | Desenvolvimento da interface mobile e web |
| Dart | Linguagem de programação do aplicativo |
| Firebase Authentication | Autenticação e recuperação de acesso |
| ESP32 | Microcontrolador do protótipo IoT |
| MQTT | Comunicação entre backend e dispositivos |
| Banco de dados relacional | Armazenamento de ambientes e dispositivos |
| Wokwi | Simulação do circuito eletrônico |
| HiveMQ | Ferramenta e ambiente de apoio aos testes MQTT |

*As tecnologias listadas correspondem ao planejamento do projeto; a utilização efetiva de cada uma depende da implementação realizada no repositório.*

## 🏗️ Arquitetura do Projeto

O COS HUB está organizado conceitualmente em três componentes principais:

### 1. Frontend
Responsável pela interface com o usuário, autenticação, navegação, gerenciamento de ambientes e interação com os dispositivos IoT. O desenvolvimento é realizado com Flutter e Dart.

### 2. Backend
Responsável pelo gerenciamento dos dados, pelas APIs, pela validação da identidade e das permissões dos usuários e pelo encaminhamento dos comandos destinados aos dispositivos.

### 3. Hardware IoT
Componente físico baseado em ESP32, responsável por receber os comandos, controlar a iluminação e comunicar o estado do dispositivo ao sistema.

A comunicação MQTT permite a troca de comandos e atualizações de estado entre os componentes envolvidos na integração IoT.

## 🚀 Como Executar o Projeto

### Pré-requisitos

Para executar a aplicação Flutter, são necessários:

- Git instalado.
- Flutter SDK instalado e configurado.
- Dart SDK compatível com o projeto.
- Visual Studio Code ou Android Studio.
- Navegador compatível ou dispositivo móvel/emulador.
- Configurações dos serviços externos utilizados pela versão do projeto.

### 1. Clone o repositório

Caso ainda não tenha o projeto em seu computador:

```bash
git clone URL_DO_SEU_REPOSITORIO
cd NOME_DO_REPOSITORIO
```

Substitua `URL_DO_SEU_REPOSITORIO` pelo endereço real do repositório e `NOME_DO_REPOSITORIO` pelo nome da pasta do projeto.

### 2. Acesse a pasta do projeto

Se o repositório já estiver clonado, abra sua pasta no VS Code e utilize o terminal integrado.

### 3. Instale as dependências

```bash
flutter pub get
```

### 4. Verifique a instalação do Flutter

```bash
flutter doctor
```

Esse comando verifica o ambiente de desenvolvimento e indica possíveis dependências que precisam ser configuradas.

### 5. Execute a aplicação

Para iniciar o aplicativo em um dispositivo conectado ou emulador:

```bash
flutter run
```

Para executar a versão web no Google Chrome, caso ela esteja configurada:

```bash
flutter run -d chrome
```

Para gerar a versão de produção para web:

```bash
flutter build web
```

**Observação:** a execução de funcionalidades que dependem do Firebase, backend, banco de dados ou broker MQTT exige que os respectivos serviços estejam configurados. Os comandos acima não configuram esses serviços automaticamente.

## 🧪 Testes e Validação

O planejamento do projeto contempla testes para verificar o funcionamento e a integração dos principais componentes:

- Cadastro, autenticação e recuperação de senha.
- Gerenciamento de propriedades, cômodos e dispositivos.
- Controle de acesso aos dados dos usuários.
- Comunicação entre backend e dispositivos por MQTT.
- Envio de comandos e atualização do estado da lâmpada.
- Controle físico e remoto da iluminação.
- Adaptação da interface para dispositivos móveis e web.

## 📦 Entregáveis do Projeto

O escopo planejado contempla:

- Aplicação multiplataforma em Flutter.
- Funcionalidades de autenticação e gerenciamento de dispositivos.
- Integração com backend e banco de dados relacional.
- Protótipo de lâmpada RGB IoT com ESP32.
- Documentação técnica e registro dos testes.
- Banner do projeto.
- Vídeo explicativo e demonstrativo.
- Relatório e apresentação acadêmica.

## 👥 Equipe de Desenvolvimento

Projeto desenvolvido por estudantes da Pontifícia Universidade Católica de Campinas:

- **Caio Ribeiro Abrahao**
- **Kaio Augusto Burilli**
- **Lucca Schroelder Scovini**
- **Paulo Cesar Whitehead Junior**
- **Pedro Henrique Ribeiro Silva Murta**
- **Raphael Fernandes de Sellos Moreira**

## 🎓 Instituição de Ensino

**Pontifícia Universidade Católica de Campinas (PUC-Campinas)**

Curso/Disciplina: Gerenciamento de Projetos de Engenharia de Software

Projeto: Projeto Integrador VI

## 📅 Planejamento

O período de referência definido no planejamento é de **3 de agosto de 2026 a 4 de dezembro de 2026**.

O cronograma contempla as etapas de planejamento, desenvolvimento da aplicação, implementação do backend, prototipagem do hardware, integração, testes e entrega dos artefatos finais.

## 🔐 Segurança

- Não compartilhe senhas, tokens de autenticação ou credenciais privadas.
-