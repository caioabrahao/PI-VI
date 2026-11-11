# Firebase e modelo de dados

## Configuração

O projeto Firebase usado pelo aplicativo é selecionado por
`pi_vi/lib/firebase_options.dart`, gerado pelo FlutterFire CLI. A configuração
do deploy das regras está em `pi_vi/firebase.json` e aponta para
`pi_vi/firestore.rules`.

Antes de executar funcionalidades remotas, é necessário configurar no projeto
Firebase:

- Authentication com E-mail/senha;
- provedor Google, incluindo domínios autorizados na web;
- Cloud Firestore;
- regras publicadas com `firebase deploy --only firestore:rules`.

Credenciais privadas não devem ser adicionadas ao repositório. Os arquivos
gerados de configuração do Firebase identificam o aplicativo cliente, mas não
substituem regras e controles de acesso.

## Autenticação

O Firebase Auth é a fonte de verdade da sessão. O Firestore guarda um perfil
auxiliar em:

```text
usuarios/{uid}
```

Campos usados pelo aplicativo incluem `uid`, `nome`, `email`, `fotoUrl`,
`cidade`, `criadoEm` e `ultimoLoginEm`. A tela de perfil lê somente a cidade
para o fluxo de edição; os demais campos são mantidos pelo cadastro ou login
Google.

## Dispositivos IoT

O caminho persistido é:

```text
usuarios/{uid}/dispositivosIot/{deviceId}
```

Modelo lógico:

| Campo | Tipo | Observação |
|---|---|---|
| `uid` | string | Deve ser igual ao usuário do caminho |
| `nome` | string | 1 a 80 caracteres |
| `identificador` | string | 1 a 128 caracteres; único por usuário no serviço |
| `tipo` | string | 1 a 50 caracteres |
| `ambienteId` | string ou nulo | Ambiente opcional |
| `statusConexao` | string | `desconhecido`, `conectado` ou `desconectado` |
| `ligado` | booleano | Estado de energia usado pela interface |
| `ultimaConexaoEm` | timestamp ou nulo | Atualizado ao conectar |
| `criadoEm` | timestamp | Timestamp do servidor |
| `atualizadoEm` | timestamp | Timestamp do servidor |

O serviço fornece:

- `cadastrar`;
- `observarDispositivos`;
- `obter`;
- `atualizarCadastro`;
- `alterarEstado`;
- `atualizarStatusConexao`;
- `excluir`.

## Regras de acesso

O acesso exige usuário autenticado e `request.auth.uid == uid`. O proprietário
pode ler e excluir seus dispositivos; criação e atualização também validam
campos, tamanhos, status e timestamps.

## Inconsistência conhecida

`DispositivoIotService` grava o campo `ligado`, mas a função
`hasValidDeviceData()` em `firestore.rules` não inclui `ligado` na lista de
campos permitidos/obrigatórios. Como consequência, operações de criação e
atualização que enviam esse campo podem ser rejeitadas pelas regras publicadas.
Essa divergência deve ser resolvida antes de considerar o fluxo completo de
dispositivos pronto em um ambiente Firebase real.

