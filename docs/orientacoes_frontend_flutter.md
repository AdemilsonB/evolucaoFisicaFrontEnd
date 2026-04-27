# Orientacoes para o Front-end Flutter

## Objetivo deste documento

Este documento consolida o contexto funcional e tecnico do projeto Evolucao Fisica, descreve o estado real do back-end Java/Spring Boot e define a base inicial recomendada para o aplicativo Flutter em `C:\dev\workspace\evolucao_fisica_app`.

O foco aqui e preparar o front para integrar com o back-end ja existente em `C:\dev\workspace\evolucaoFisica` sem inventar contratos, sem misturar entidades planejadas com execucoes reais e sem acoplar a UI a premissas que ainda nao estao estaveis.

## Fontes analisadas

### Documentacao de produto

- `C:\dev\workspace\evolucaoFisica\CLAUDE.md`
- `C:\dev\workspace\evolucaoFisica\arquivos\produto\funcionalidades_sistema.md`
- `C:\dev\workspace\evolucaoFisica\arquivos\produto\backlog_priorizado.md`

### Codigo do back-end

- controllers, dto, config, exception, service, entity e resources em `C:\dev\workspace\evolucaoFisica\src\main`
- configuracao de seguranca JWT e Google OAuth
- migracoes Flyway `V1`, `V2` e `V3`

### Codigo atual do Flutter

- `C:\dev\workspace\evolucao_fisica_app\pubspec.yaml`
- `C:\dev\workspace\evolucao_fisica_app\lib\main.dart`
- estrutura padrao criada pelo Flutter

## Leitura de contexto do produto

O sistema e uma plataforma fitness gamificada com cinco macro frentes:

1. Identidade, autenticacao e onboarding.
2. Treinos planejados e execucao real.
3. Alimentacao planejada e execucao real.
4. Gamificacao com XP, nivel, medalhas, missoes e ranking.
5. Social, visibilidade e comunidade.

As regras mais importantes para o front respeitar desde o primeiro commit sao:

- Nunca misturar treino planejado com `RegistroTreino`.
- Nunca misturar plano alimentar com `RegistroDiario` ou refeicao real.
- Nao inferir XP, nivel, medalhas ou ranking no cliente.
- Nao gerar estados ficticios para "simular" progresso.
- Tratar privacidade e ownership como parte do fluxo da interface, nao como detalhe.

## Estado real do back-end

### Arquitetura

O back-end segue a estrutura em camadas:

`controller -> service -> repository`

Pastas principais encontradas:

- `config`
- `controller`
- `dto`
- `entity`
- `enumeration`
- `exception`
- `repository`
- `service`

### Seguranca

- JWT stateless com `Authorization: Bearer <token>`
- endpoints publicos atuais:
  - `POST /api/auth/cadastro`
  - `POST /api/auth/login`
  - `POST /api/auth/google`
  - `POST /api/usuarios`
- todo o restante exige autenticacao

### Infra

- Spring Boot
- PostgreSQL
- Flyway habilitado
- `server.port: 8080`
- `ddl-auto: validate`

### Observacao importante sobre especificacao vs implementacao

Os documentos de contexto citam API versionada em `/api/v1` e listagens paginadas. Porem, a implementacao atual expoe rotas em `/api/...` e varios endpoints ainda retornam listas simples. O front deve integrar com o estado real do codigo atual, mas manter a camada de dados desacoplada para absorver uma futura versao `/api/v1` e paginacao sem refatoracao ampla.

## Modulos do back-end ja expostos por endpoint

### Autenticacao e identidade

- `POST /api/auth/cadastro`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/autenticacao/identidades`
- `GET /api/autenticacao/identidades/usuarios/{usuarioId}`

Payload confirmado para login local:

```json
{
  "email": "usuario@dominio.com",
  "senha": "senha"
}
```

Resposta confirmada:

```json
{
  "accessToken": "jwt",
  "tokenType": "Bearer",
  "expiraEm": "2026-04-27T10:00:00",
  "onboardingPendente": true,
  "usuario": {}
}
```

### Usuario, onboarding e metas

- `POST /api/usuarios`
- `GET /api/usuarios/{id}`
- `PUT /api/usuarios/{id}`
- `PATCH /api/usuarios/{id}/peso`
- `POST /api/usuarios/{usuarioId}/onboarding`
- `GET /api/usuarios/{usuarioId}/metas`
- `PUT /api/usuarios/{usuarioId}/metas`

Enums confirmados para onboarding:

- `Objetivo`: `GANHO_MASSA`, `DEFINICAO`, `MANUTENCAO`, `EMAGRECIMENTO`
- `NivelExperiencia`: `INICIANTE`, `INTERMEDIARIO`, `AVANCADO`

### Treinos

- `GET /api/treinos`
- `GET /api/treinos/agenda-semanal`
- `GET /api/treinos/agenda-dia`
- `POST /api/treinos`
- `PUT /api/treinos/{id}`
- `POST /api/treinos/{id}/exercicios`
- `DELETE /api/treinos/{id}/exercicios/{treinoExercicioId}`
- `GET /api/exercicios`
- `POST /api/exercicios`
- `GET /api/registros-treino`
- `POST /api/registros-treino`
- `PUT /api/registros-treino/{id}/inicio`
- `POST /api/registros-treino/{id}/execucoes`
- `PUT /api/registros-treino/{id}/finalizacao`
- `PUT /api/registros-treino/{id}/aborto`

Enums confirmados para execucao:

- `StatusExecucaoTreino`: `PLANEJADO`, `INICIADO`, `CONCLUIDO`, `ABORTADO`
- `MotivacaoRegistro`: `ALTA`, `MEDIA`, `BAIXA`
- `TipoTreino`: `A`, `B`, `C`, `FULL_BODY`

### Alimentacao

- `GET /api/alimentos`
- `POST /api/alimentos`
- `GET /api/planos-alimentares`
- `POST /api/planos-alimentares`
- `GET /api/planos-alimentares/dia-da-semana`
- `GET /api/planos-alimentares/execucao-dia`
- `POST /api/planos-alimentares/{id}/dias`
- `POST /api/planos-alimentares/dias/{planoDiaId}/refeicoes`
- `POST /api/planos-alimentares/refeicoes/{planoRefeicaoId}/alimentos`
- `GET /api/refeicoes`
- `POST /api/refeicoes`
- `POST /api/refeicoes/{id}/alimentos`

### Gamificacao

- `POST /api/gamificacao/registros-diarios`
- `GET /api/gamificacao/registros-diarios`
- `GET /api/gamificacao/dashboard/{usuarioId}`
- `GET /api/gamificacao/ranking/geral`
- `GET /api/gamificacao/ranking/seguindo/{usuarioId}`
- `GET /api/gamificacao/ranking/grupo/{grupoId}`

### Social

- `POST /api/social/usuarios/{seguidorId}/seguir/{seguidoId}`
- `GET /api/social/usuarios/{usuarioId}/seguidores`
- `GET /api/social/usuarios/{usuarioId}/seguindo`
- `POST /api/social/grupos`
- `GET /api/social/grupos`
- `POST /api/social/grupos/{grupoId}/membros`
- `POST /api/social/postagens`
- `GET /api/social/postagens/feed`
- `GET /api/social/usuarios/{usuarioId}/postagens`
- `POST /api/social/postagens/{postagemId}/curtidas`
- `POST /api/social/postagens/{postagemId}/comentarios`

## Analise do projeto Flutter atual

Estado encontrado:

- `lib/` contem apenas `main.dart`
- `pubspec.yaml` ainda esta no estado padrao
- nao existe camada de rede
- nao existe persistencia de sessao
- nao existe organizacao por feature
- nao existe separacao entre UI e integracao

Tambem foi encontrada a pasta `C:\dev\workspace\evolucao_fisica_app\evolucaoFisicaFrontEnd`, atualmente vazia. Como nao participa da estrutura padrao do Flutter e nao contem codigo util, ela deve ser tratada como resquicio e ignorada nesta primeira base. Se permanecer sem uso, pode ser removida depois com seguranca.

## Arquitetura Flutter recomendada

### Objetivo da estrutura

Criar uma base pequena, mas correta para:

- autenticar com JWT
- persistir sessao
- chamar o back-end com tratamento padronizado de erro
- organizar o app por feature
- suportar a expansao natural para treino, alimentacao, gamificacao e social

### Estrutura proposta

```text
lib/
  main.dart
  src/
    app/
      app_router.dart
      app_widget.dart
    core/
      config/
      constants/
      di/
      models/
      network/
      storage/
      theme/
    features/
      auth/
      onboarding/
      dashboard/
```

### Responsabilidade por camada

- `app`: bootstrap, roteamento e composicao global.
- `core/config`: configuracoes de ambiente, especialmente `API_BASE_URL`.
- `core/constants`: caminhos de endpoint e chaves fixas.
- `core/di`: montagem de dependencias compartilhadas.
- `core/models`: modelos reutilizaveis, como `AppUser`.
- `core/network`: cliente HTTP, injecao de JWT e normalizacao de erros.
- `core/storage`: persistencia local da sessao.
- `core/theme`: identidade visual inicial do app.
- `features/*`: codigo por modulo de negocio, com repositorios, modelos e paginas.

## Regras de integracao para o Flutter

### 1. Base URL por ambiente

Usar `--dart-define=API_BASE_URL=...` e nunca hardcode espalhado em widgets.

Sugestoes comuns:

- Android emulator: `http://10.0.2.2:8080`
- iOS simulator: `http://localhost:8080`
- dispositivo fisico: IP da maquina na rede local

### 2. JWT

- salvar `accessToken` localmente
- anexar `Authorization: Bearer <token>` em todas as rotas protegidas
- tratar `401` como sessao invalida ou expirada

### 3. Erros

Padronizar consumo do back-end usando `message` como fonte primaria. O cliente nao deve exibir stack trace nem depender da estrutura interna de excecoes.

### 4. Enums

Enums do back-end devem ser enviados como `String` em uppercase exatamente como a API espera. A UI pode exibir rotulos amigaveis, mas a camada de dados precisa preservar os valores originais.

### 5. Plano vs execucao

Modelos separados no cliente tambem. Exemplos:

- `Treino` nao deve carregar estado mutavel de execucao em memoria como se fosse `RegistroTreino`.
- `PlanoAlimentar` nao deve ser reutilizado como modelo de refeicao consumida.

### 6. Gamificacao

O front so apresenta os dados vindos de `dashboard`, `ranking`, `missoes` e `historicoXp`. Regras de concessao de XP, medalhas e streak nunca devem ser duplicadas no Flutter.

## Arquivos fundamentais criados nesta base inicial

### Infraestrutura

- configuracao central de ambiente
- cliente HTTP com `dio`
- armazenamento de sessao com `shared_preferences`
- tratamento de erro unificado
- tema base do aplicativo

### Features iniciais

- `auth`: login local, persistencia de sessao e logout
- `onboarding`: formulario alinhado aos enums e campos atuais do back-end
- `dashboard`: leitura do dashboard gamificado e ranking geral

## Convencoes de desenvolvimento para as proximas features

1. Todo endpoint novo entra primeiro em `ApiPaths`.
2. Toda chamada remota passa por `ApiClient`.
3. Cada feature mantem seus modelos e repositorios.
4. Widgets nao montam URL, header ou parsing JSON manual.
5. Quando o back-end evoluir para paginacao, a mudanca deve ficar concentrada no repositorio da feature.

## Proximas etapas recomendadas

1. Adicionar cadastro local e login Google na feature `auth`.
2. Criar tela de metas do atleta aproveitando `GET/PUT /api/usuarios/{usuarioId}/metas`.
3. Criar modulos `treinos` e `registros_treino` separados desde o inicio.
4. Criar modulos `planos_alimentares` e `refeicoes` separados desde o inicio.
5. Evoluir o roteamento para guards de autenticacao e expiracao de sessao.
6. Padronizar serializacao com code generation se o numero de DTOs crescer.

## Resumo executivo

O back-end ja tem um dominio relativamente amplo e uma fundacao importante pronta. O Flutter, por outro lado, ainda estava em estado inicial. A base criada nesta entrega prepara o app para a integracao real com autenticacao, onboarding e dashboard, mantendo a arquitetura leve e pronta para crescer sem quebrar as regras centrais do produto.
