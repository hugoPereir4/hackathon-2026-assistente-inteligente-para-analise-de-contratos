# Company

Dados da empresa logada. Não existe rota para listar empresas ou acessar outra empresa: a rota sempre opera sobre a conta dona do token.

Base URL: `/api/v1/companies/`

Todas as rotas, exceto `GET /api/v1/companies/{cnpj}/`, exigem o header:

```
Authorization: Bearer <access>
```

Veja como obter o token em [auth/docs/index.md](../../auth/docs/index.md).

| Método | Rota                     | Descrição                        |
| ------ | ------------------------ | -------------------------------- |
| GET    | `/api/v1/companies/me/`  | Retorna os dados da empresa logada |
| PATCH  | `/api/v1/companies/me/`  | Atualiza um ou mais campos (inclusive a senha) |
| DELETE | `/api/v1/companies/me/`  | Exclui a conta definitivamente   |
| GET    | `/api/v1/companies/{cnpj}/` | Consulta o CNPJ na Receita para preencher o cadastro (pública) |

> `PUT` não é aceito (responde `405`). Use `PATCH`.

---

## Objeto `Company`

| Campo           | Tipo              | Editável | Observação |
| --------------- | ----------------- | -------- | ---------- |
| `id`            | number            | Não      | |
| `cnpj`          | string            | Não      | 14 caracteres, sem pontuação. Definido no cadastro. |
| `email`         | string            | Sim      | Salvo em minúsculas. Deve ser único. |
| `legal_name`    | string \| null    | Sim      | Razão social. |
| `cnae_primary`  | string \| null    | Sim      | CNAE principal. |
| `company_size`  | string \| null    | Sim      | Porte da empresa (texto livre). |
| `founded_on`    | string \| null    | Sim      | Data de abertura, formato `YYYY-MM-DD`. |
| `address_city`  | string \| null    | Sim      | |
| `address_state` | string \| null    | Sim      | UF, máximo 2 caracteres (ex.: `"SP"`). |
| `confirmed`     | boolean           | Sim      | `true` quando o usuário confirmou os dados vindos da API de CNPJ. Padrão `false`. |
| `created_at`    | string (ISO 8601) | Não      | |

```json
{
  "id": 1,
  "cnpj": "12345678000195",
  "email": "contato@empresa.com.br",
  "legal_name": "Empresa Exemplo LTDA",
  "cnae_primary": "6201-5/01",
  "company_size": "ME",
  "founded_on": "2015-03-10",
  "address_city": "São Paulo",
  "address_state": "SP",
  "confirmed": true,
  "created_at": "2026-10-17T14:32:10.123456-03:00"
}
```

---

## GET `/api/v1/companies/me/`

### Resposta `200 OK`

O objeto `Company` acima.

---

## PATCH `/api/v1/companies/me/`

Envie só os campos que mudaram. Campos não editáveis (`id`, `cnpj`, `created_at`) são ignorados se enviados.

### Body

```json
{
  "legal_name": "Empresa Exemplo S.A.",
  "address_city": "Campinas",
  "confirmed": true
}
```

Para trocar a senha, envie `password` (pode ir junto com outros campos):

```json
{ "password": "NovaSenhaForte456" }
```

A senha passa pelos mesmos validadores do cadastro e nunca é devolvida na resposta. Os tokens atuais continuam válidos depois da troca.

### Resposta `200 OK`

O objeto `Company` atualizado.

### Erros `400 Bad Request`

```json
{
  "email": ["company com este email já existe."],
  "founded_on": ["Formato inválido para data. Use um dos formatos a seguir: YYYY-MM-DD."],
  "address_state": ["Certifique-se de que este campo não tenha mais de 2 caracteres."],
  "password": ["Esta senha é muito curta. Ela precisa conter pelo menos 8 caracteres."]
}
```

---

## DELETE `/api/v1/companies/me/`

Exclui a conta de forma definitiva, junto com todos os fatos e documentos da empresa. Não há como desfazer: peça confirmação ao usuário antes de chamar.

### Resposta `204 No Content`

Sem corpo. Depois disso, apague os tokens do front e mande o usuário para a tela de login.

---

## GET `/api/v1/companies/{cnpj}/`

Consulta o CNPJ na [Minha Receita](https://minhareceita.org/) e devolve os dados com os mesmos nomes de campo do objeto `Company`, para o front preencher a tela de cadastro.

- **Pública:** não precisa de `Authorization`, porque o usuário ainda não tem conta.
- **Não salva nada.** Só consulta e devolve.
- `{cnpj}` vai **sem a barra** (`/` quebra a URL). Pode mandar só os 14 caracteres (`33000167000101`) ou com pontos e traço (`33.000.1670001-01`).
- Limite de 15 req/min por IP, como as outras rotas sem login.

### Resposta `200 OK`

```json
{
  "cnpj": "33000167000101",
  "legal_name": "PETROLEO BRASILEIRO S A PETROBRAS",
  "cnae_primary": "0600-0/01",
  "company_size": "DEMAIS",
  "founded_on": "1966-09-28",
  "address_city": "RIO DE JANEIRO",
  "address_state": "RJ"
}
```

Qualquer campo pode vir `null` se a Receita não tiver o dado. `company_size` vem como a Receita informa: `"MICRO EMPRESA"`, `"EMPRESA DE PEQUENO PORTE"` ou `"DEMAIS"`.

### Erros

| Status | Quando |
| ------ | ------ |
| `400`  | CNPJ inválido (formato ou dígito verificador). Ex.: `{ "cnpj": ["CNPJ inválido."] }` |
| `404`  | CNPJ válido, mas não encontrado na Receita. Ex.: `{ "detail": "CNPJ não encontrado na Receita." }` |
| `429`  | Mais de 15 consultas por minuto. |
| `502`  | A Minha Receita está fora do ar ou demorou mais de 10 s. Pode tentar de novo. |

---

## Erros comuns a todas as rotas

| Status | Quando |
| ------ | ------ |
| `401`  | Header `Authorization` ausente, ou `access` inválido/expirado. Tente `/auth/refresh/`. |
| `405`  | Método não suportado (ex.: `PUT`, `POST`). |
| `429`  | Limite de 50 req/min por usuário excedido. |

Exemplo de `401`:

```json
{
  "detail": "O token informado não é válido para qualquer tipo de token",
  "code": "token_not_valid",
  "messages": [
    { "token_class": "AccessToken", "token_type": "access", "message": "O token é inválido ou expirado" }
  ]
}
```
