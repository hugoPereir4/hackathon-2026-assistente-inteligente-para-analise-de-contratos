# Auth

Cadastro, login e gestão de tokens JWT da empresa (`Company` é o único tipo de usuário).

Base URL: `/api/v1/auth/`

| Método | Rota                    | Autenticação | Descrição                          |
| ------ | ----------------------- | ------------ | ---------------------------------- |
| POST   | `/api/v1/auth/register/` | Não          | Cria a conta e já devolve os tokens |
| POST   | `/api/v1/auth/login/`    | Não          | Login com email **ou** CNPJ        |
| POST   | `/api/v1/auth/refresh/`  | Não          | Gera um novo `access` a partir do `refresh` |
| POST   | `/api/v1/auth/logout/`   | Não          | Invalida o `refresh` token         |

## Como autenticar as demais rotas

Envie o `access` token no header:

```
Authorization: Bearer <access>
```

Validade padrão (SimpleJWT, sem configuração própria no projeto):

- `access`: 5 minutos
- `refresh`: 1 dia

Quando uma rota protegida responder `401`, chame `/auth/refresh/` e repita a requisição. Se o refresh também falhar, mande o usuário para o login.

O payload do `access` traz `user_id` (id da empresa) e `name` (razão social, ou o email se não houver).

---

## POST `/api/v1/auth/register/`

Cria a empresa e já retorna os tokens, então não é preciso chamar o login em seguida.

### Body

| Campo        | Tipo   | Obrigatório | Observação |
| ------------ | ------ | ----------- | ---------- |
| `email`      | string | Sim         | Salvo em minúsculas. Deve ser único. |
| `password`   | string | Sim         | Passa pelos validadores do Django: mínimo 8 caracteres, não pode ser só numérica, comum ou parecida com o email. |
| `cnpj`       | string | Sim         | Aceita com ou sem pontuação (`12.345.678/0001-95` ou `12345678000195`), numérico ou alfanumérico. Salvo só com os 14 caracteres. Deve ser único. |

```json
{
  "email": "contato@empresa.com.br",
  "password": "SenhaForte123",
  "cnpj": "12.345.678/0001-95"
}
```

### Resposta `201 Created`

```json
{
  "user": {
    "id": 1,
    "email": "contato@empresa.com.br",
    "cnpj": "12345678000195"
  },
  "access": "<jwt>",
  "refresh": "<jwt>"
}
```

### Erros `400 Bad Request`

Formato padrão do DRF: um objeto com a lista de mensagens de cada campo.

```json
{
  "email": ["Já existe uma conta com este email."],
  "cnpj": ["CNPJ inválido."]
}
```

Mensagens possíveis:

- `email`: `"Já existe uma conta com este email."`, email inválido
- `cnpj`: `"CNPJ inválido."`, `"Já existe uma conta com este CNPJ."`
- `password`: mensagens dos validadores de senha do Django (a chave pode vir como `non_field_errors`)

---

## POST `/api/v1/auth/login/`

O campo de login aceita email ou CNPJ, com ou sem pontuação. Se o valor tiver `@`, é tratado como email.

### Body

```json
{
  "login": "contato@empresa.com.br",
  "password": "SenhaForte123"
}
```

ou

```json
{
  "login": "12.345.678/0001-95",
  "password": "SenhaForte123"
}
```

### Resposta `200 OK`

```json
{
  "refresh": "<jwt>",
  "access": "<jwt>"
}
```

### Erros

- `400`: campo `login` ou `password` ausente
- `401`: credenciais inválidas

```json
{ "detail": "Nenhuma conta ativa foi encontrada com as credenciais fornecidas" }
```

---

## POST `/api/v1/auth/refresh/`

### Body

```json
{ "refresh": "<jwt>" }
```

### Resposta `200 OK`

```json
{ "access": "<jwt>" }
```

O `refresh` não é rotacionado: continue usando o mesmo até ele expirar.

### Erros

- `401`: refresh inválido ou expirado

```json
{ "detail": "O token é inválido ou expirado", "code": "token_not_valid" }
```

---

## POST `/api/v1/auth/logout/`

### Body

```json
{ "refresh": "<jwt>" }
```

### Resposta `200 OK`

```json
{}
```

Depois do logout, apague os dois tokens do armazenamento do front.

### Erros

- `401`: refresh inválido ou expirado

---

## Limite de requisições

| Situação             | Limite        |
| -------------------- | ------------- |
| Sem autenticação     | 15 req/min    |
| Autenticado          | 50 req/min    |

Acima do limite a API responde `429 Too Many Requests` com `{"detail": "..."}`.
