# Frontend — Assistente Inteligente para Análise de Contratos

App Flutter (web, Android e iOS) do Desafio 12 do Hackathon 2026.
Usa Material na web/Android e Cupertino no iOS (`lib/core/platform/app_platform.dart`).

## Como rodar

Por padrão o app usa **dados mockados** e funciona sem backend:

```bash
flutter run -d chrome
```

Para usar a **API Django** (branch `main`):

```bash
flutter run -d chrome --dart-define=USE_API=true --dart-define=API_URL=http://localhost:8000
```

- No emulador Android use `API_URL=http://10.0.2.2:8000`.
- Na web o backend precisa liberar CORS para a origem do app.
- Para ver o visual Cupertino no navegador: `--dart-define=UI_STYLE=cupertino`.

## Testes

```bash
flutter test
```

## Estrutura (MVC)

```
lib/
  core/         config, DI, rede (ApiClient/JWT), rotas, tema, utils
  models/       dados no formato do JSON da API
  services/     contratos (abstratos)
    api/        implementações HTTP
    mock/       implementações em memória (padrão)
  controllers/  regras de tela (ChangeNotifier)
  views/        telas e componentes adaptativos
```

A troca entre mock e API acontece só em `lib/core/di/app_dependencies.dart`.

## Integração com o backend

| Tela | Endpoint |
| --- | --- |
| Login | `POST /api/v1/auth/login/` `{login, password}` + `GET /api/v1/users/` |
| Cadastro | `POST /api/v1/auth/register/` + `PATCH /api/v1/users/{id}/` |
| Confirmar empresa | `GET /api/v1/users/` + `PATCH /api/v1/users/{id}/` (`confirmed: true`) |
| Página inicial | `GET/POST /api/v1/documents/`, `GET /api/v1/documents/{id}/` |
| Resultado da análise | `GET /api/v1/documents/{id}/` (`score`, `outcome`, `analysis_json`) |
| Sair | `POST /api/v1/auth/logout/` |

O formato do `analysis_json` (JSON devolvido pela IA, `schema_version` 1) está
documentado em `lib/models/analise_detalhe.dart`, e há um exemplo real em
`test/fixtures/analise_exemplo.json`.

Ainda falta no backend: CORS, consulta pública de CNPJ (o app chama
`GET /api/v1/cnpj/{cnpj}/`), expor `score`/`outcome`/`analysis_json` dos
documentos e o app `token_blacklist` do SimpleJWT para o logout.
