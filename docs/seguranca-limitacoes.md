# Segurança, limitações e próximos passos

## Controles existentes

- O acesso aos documentos de dispositivos é separado por `uid`.
- As regras Firestore exigem autenticação e conferem o proprietário.
- Campos de dispositivo possuem lista permitida, tipos e limites de tamanho.
- Timestamps de criação/atualização usam horário do servidor nas operações do
  serviço.
- Login por senha exige verificação de e-mail.
- Erros de autenticação são convertidos em mensagens compreensíveis.
- O código não deve receber senhas, tokens ou chaves privadas em commits.

## Pontos de atenção

1. Corrigir a divergência do campo `ligado` entre o serviço e
   `firestore.rules`.
2. Confirmar se a regra ampla de leitura/escrita em `usuarios/{uid}` é
   compatível com todos os campos do perfil; hoje ela permite ao próprio
   usuário alterar o documento inteiro.
3. Substituir identificadores gerados pelo aplicativo por identificadores
   reais do hardware quando a integração IoT existir.
4. Adicionar testes das regras com Firebase Emulator Suite.
5. Evitar exibir detalhes internos de exceções em produção quando eles
   contiverem informações operacionais.
6. Revisar nomes de pacote, application ID, bundle ID e títulos antes de
   publicar.

## Limitações funcionais atuais

- Ambientes são listas locais do dashboard; não há CRUD persistido de
  propriedades/cômodos.
- Automações não persistem brilho, cor, agenda, temporizadores ou consumo.
- Alertas são criados e lidos somente em memória.
- O estado `ligado` é salvo no Firestore, mas não é enviado a um dispositivo
  físico.
- Status de conexão é informado pelo aplicativo; não existe heartbeat ou
  confirmação do hardware.
- Raspberry Hub, MQTT Broker, Home Assistant e Pi-hole são telas
  demonstrativas.
- Não existe código de ESP32, firmware, broker, tópico MQTT ou ponte entre
  Firestore e MQTT.
- A configuração Linux do Firebase está ausente.

## Próximos passos sugeridos

### Persistência e backend

- alinhar regras e modelo do Firestore;
- criar modelo persistido para ambientes;
- definir índices, consultas e política de exclusão;
- adicionar emuladores e testes de regras.

### Integração IoT

- definir contrato de mensagens MQTT e tópicos por dispositivo;
- implementar autenticação do broker;
- criar firmware ESP32 e heartbeat;
- separar comando desejado, estado reportado e última confirmação;
- refletir falhas de entrega na interface.

### Produto

- persistir automações e alertas;
- substituir dados demonstrativos por dados reais;
- adicionar estados de carregamento e erro consistentes;
- validar acessibilidade e comportamento responsivo por plataforma;
- preparar configuração de release e observabilidade.

